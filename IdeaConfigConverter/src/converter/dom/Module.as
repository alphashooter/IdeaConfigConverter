package converter.dom {
import converter.FileHelper;
import converter.StringUtil;

import flash.filesystem.File;

public class Module {

		public static const TYPE_AS : String = "AS";
		public static const TYPE_FLEX : String = "Flex";

		public static const OUTPUT_TYPE_APPLICATION : String = "Application";
		public static const OUTPUT_TYPE_LIBRARY : String = "Library";
		public static const OUTPUT_TYPE_RUNTIME : String = "...";

		public static const TARGET_PLATFORM_DESKTOP : String = "Desktop";
		public static const TARGET_PLATFORM_MOBILE : String = "Mobile";

		public static const DEFAULT_SOURCE_DIRECTORY : String = "src";

		private var _file : File;
		private var _relativePath : String;
		private var _content : XML;
		private var _info : String;
		private var _type : String;
		private var _configurationXML : XML;
		private var _dependedLibs : Vector.<LibDependency>;
		private var _outputType : String;
		private var _name : String;
		private var _flashPlayerVersion : String;
		private var _dependenciesXML : XML;
		private var _sdkVersion : String;
		private var _moduleType : String;
		private var _relativeDirectoryPath : String;
		private var _project : Project;
		private var _sourceDirectoryURLs : Vector.<String>;
		private var _mainClass : String;
		private var _targetPlatform : String;
		private var _outputDirectory : String;
		private var _outputFile : String;
		private var _dependedModules : Vector.<ModuleDependency>;
		public var moduleRoot : ModuleRoot;
		private var _configurationID : uint;
		private var _directory : File;
		private var _srcDirs : Vector.<String>;

		public function Module(project : Project, file : File, moduleRoot : ModuleRoot, configurationID : uint) {
			_project = project;
			_file = file;
			this.moduleRoot = moduleRoot;
			_configurationID = configurationID;
		}

		public function get relativePath() : String {
			return _relativePath ||= _project.directory.getRelativePath(_file);
		}

		public function get relativeDirectoryPath() : String {
			return _relativeDirectoryPath ||= _project.directory.getRelativePath(_file.parent);
		}

		public function get relativePomDirecoryPath() : String {
			return _project.directory.getRelativePath(pomDirectory);
		}

		public function get directory() : File {
			return _directory ||= getDirectory();
		}

		private function getDirectory() : File {
			var urls : XMLList = content.component.content.@url;
			var url : String;
			if (urls.length() == 1) {
				url = urls;
			} else {
				var minLength : uint = uint.MAX_VALUE;
				for each(var possibleURL : String in urls) {
					if (!url || possibleURL.length < minLength) {
						url = possibleURL;
						minLength = possibleURL.length;
					}
				}
			}
			url = url.replace("file://$MODULE_DIR$", "");
			return url ? _file.parent.resolvePath(url.substr(1)) : _file.parent;

		}

		public function get dependedModules() : Vector.<ModuleDependency> {
			return _dependedModules ||= getDependedModules();
//			return Module.xmlListToVector(content.component.orderEntry.(@type == "module").attribute("module-name"));
		}

		public function getDependedModules() : Vector.<ModuleDependency> {
			var moduleDependencies : Vector.<ModuleDependency> = new Vector.<ModuleDependency>();
			for each(var entry : XML in configurationXML.dependencies.entries.entry.(attribute("module-name").length())) {
				moduleDependencies.push(new ModuleDependency(entry.attribute("build-configuration-name"), entry.dependency.@linkage));
			}
			return moduleDependencies;
		}

		public function get content() : XML {
			return _content ||= readFileContent();
		}

		private function readFileContent() : XML {
			return XML(FileHelper.readFile(_file));
		}

		public function get info() : String {
			return _info ||= readInfo();
		}

		private function readInfo() : String {
			var result : Vector.<String> = new Vector.<String>();
			result.push("\tName:");
			result.push(name);
			result.push("\tType:");
			result.push(type);
			result.push("\tOutput type:");
			result.push(outputType);
			result.push("\tPath:");
			result.push(relativePath);
			result.push("\tDepends on modules:");
			result.push(dependedModules.join('\n'));
			result.push("\tDepends on libs:");
			result.push(dependedLibs.join('\n'));
			result.push("\tFlash player:");
			result.push(flashPlayerVersion);
			//result.push(_moduleRoot.xml.groupId);
			return result.join("\n");
		}


		public function get name() : String {
			return _name ||= configurationXML.attribute("name");
		}

		public function get dependedLibs() : Vector.<LibDependency> {
			return _dependedLibs ||= getDependedLibs();
		}

		private function getDependedLibs() : Vector.<LibDependency> {
//			var libs : Vector.<Lib> = new Vector.<Lib>();
//			for each(var extLibXML : XML in content.component.orderEntry.(@type == "library")) {
//				libs = libs.concat(_project.getLibByName(extLibXML.@name));
//			}
//			for each(var intLibXML : XML in content.component.orderEntry.(@type == "module-library")) {
//				libs = libs.concat(Lib.resolveFileFromInternalDependably(intLibXML.library.CLASSES.root.@url, directory, intLibXML));
//			}
//			return libs;

			var dependencies : Vector.<LibDependency> = new Vector.<LibDependency>();
			for each(var lib : XML in configurationXML.dependencies.entries.entry.(attribute("library-id").length())) {
				var inLib : XML = content.component.orderEntry.library.(properties.@id == lib.attribute("library-id"))[0];
				addLibDependency(lib.dependency.@linkage, dependencies, (Lib.resolveFileFromInternalDependably(inLib.CLASSES.root.@url, directory, inLib)));
			}
			for each(var topLib : XML in configurationXML.dependencies.entries.entry.(attribute("library-name").length())) {
				addLibDependency(topLib.dependency.@linkage, dependencies, _project.getLibByName(topLib.attribute("library-name")));
			}
			return dependencies;
		}

		private function addLibDependency(linkage : String, dependencies : Vector.<LibDependency>, libs : Vector.<Lib>) : void {
			for each(var lib : Lib in libs) {
				dependencies.push(new LibDependency(lib, linkage));
			}
		}

		public function get type() : String {
			return _type ||= configurationXML.attribute("pure-as") == "true" ? TYPE_AS : TYPE_FLEX;
		}

		public function get configurationXML() : XML {
			return _configurationXML ||= getConfigurationsXML(content)[_configurationID];
		}

		public static function getConfigurationsXML(xml : XML) : XMLList {
			return xml.component.configurations.configuration;
		}

		public function get dependenciesXML() : XML {
			return _dependenciesXML ||= configurationXML.dependencies[0];
		}

		public function get outputType() : String {
			return _outputType ||= configurationXML.attribute("output-type");
		}

		public function getOptionValue(key : String) : String {
			return content.component.option.(@name == key).@value;
		}

		public function get flashPlayerVersion() : String {
			return moduleRoot.flashPlayerVersion;
//			return _flashPlayerVersion ||= dependenciesXML.attribute("target-player");
		}

		public function get sdkVersion() : String {
			return moduleRoot.sdkVersion;
//			return _sdkVersion ||= dependenciesXML.sdk.@name;
		}

		public function get moduleType() : String {
			return _moduleType ||= content.@type;
		}

		public function get mainClass() : String {
			return _mainClass ||= configurationXML.attribute("main-class");
		}

		public function get targetPlatform() : String {
			return _targetPlatform ||= configurationXML.attribute("target-platform");
		}

		public function get outputDirectory() : String {
			return _outputDirectory ||= StringUtil.replace(configurationXML.attribute("output-folder"), "$MODULE_DIR$/", "");
		}

		public function get outputFile() : String {
			return _outputFile ||= configurationXML.attribute("output-file");
		}

		public function get sourceDirectoryURLs() : Vector.<String> {
			return _sourceDirectoryURLs ||= getSourceDirectoryURLs();
		}

		private function getSourceDirectoryURLs() : Vector.<String> {
			var sources : Vector.<String> = new Vector.<String>();
			for each(var url : String in  content.component.(@name == "NewModuleRootManager").content.sourceFolder.@url) {
				sources.push(url.replace("file://$MODULE_DIR$/", ""));
			}
			return sources;
		}

		public static function xmlListToVector(xmlList : XMLList) : Vector.<String> {
			var strings : Vector.<String> = new Vector.<String>();
			for each(var item : String in xmlList) {
				strings.push(String(item));
			}
			return strings;
		}

		public function get groupID() : String {
			return moduleRoot.groupID;
		}

		public function get version() : String {
			return moduleRoot.version;
		}

		public function get pomDirectory() : File {
			return moduleRoot.directory.resolvePath(_project.pomDirectory.name + "/" + name);
		}

		public function get namespaceURI() : String {
			for (var namespaceURI : String in namespaces) {
				return namespaceURI;
			}
			return null;
		}

		private function get namespaces() : Object {
			var namespaces : Object = {};
			var entries : XMLList = configurationXML["compiler-options"].map.entry.(@key == "compiler.namespaces.namespace");
			for each(var ns : XML in entries) {
				var nsData : String = ns.@value;
				if (nsData && nsData.length > 0) {
					var splitted : Array = nsData.split("\t");
					namespaces[splitted[0]] = splitted[1];
				}
			}
			return namespaces;
		}

		public function get defines() : Array {
			var entries : XMLList = configurationXML["compiler-options"].map.entry.(@key == "compiler.define");
			if(entries.length()) {
				var value:String = entries[0].@value;
				return StringUtil.replace(value, "\t", ",").split("\n");
			}
			return null;
		}

		public function get namespaceLocation() : String {
			for each(var namespaceLocation : String in namespaces) {
				namespaceLocation = namespaceLocation.replace("$MODULE_DIR$/", "");
				return _project.pomDirectory.getRelativePath(directory.resolvePath(namespaceLocation), true);
//				return pomDirectory.getRelativePath(directory.resolvePath(namespaceLocation), true);
			}
			return null;
		}

		public function get extraSources() : Array {
			return null;
		}

		public function get isAIR() : Boolean {
			var platform : String = _configurationXML.attribute("target-platform");
			return ["Desktop", "Mobile"].indexOf(platform) >= 0;
		}

		public function getCerteficate(platform : String) : File {
			var url : String = String(getMobileSigningOptions(platform).attribute("keystore-path")).replace("$MODULE_DIR$/", "");
			return directory.resolvePath(url);
		}

		public function get provision() : File {
			var url : String = String(getMobileSigningOptions("ios").attribute("provisioning-profile-path")).replace("$MODULE_DIR$/", "");
			return directory.resolvePath(url);
		}

		public function getKeystoreType(platform : String) : String {
			return String(getMobileSigningOptions(platform).attribute("keystore-type"));
		}

		private function getMobileSigningOptions(platform : String) : XMLList {
			return XMLList(getMobileConfig(platform).AirSigningOptions);
		}

		public function getDescriptor(platform : String) : File {
			var url : String = String(getMobileConfig(platform).attribute("custom-descriptor-path")).replace("$MODULE_DIR$/", "");
			return directory.resolvePath(url);
		}

		private function getMobileConfig(platform : String) : XML {
			return XMLList(configurationXML["packaging-" + platform])[0] || new XML;
		}

		public function getMobileResources(platform : String) : Object {
			var files : XMLList = getMobileConfig(platform)["files-to-package"].FilePathAndPathInPackage;
			var map : Object = {};
			for each(var xml : XML in files) {
				var base : String = String(xml.attribute("file-path"));
				// todo: resolve relative path instead
				base = base.replace("$MODULE_DIR$/", "../");
				var exp : String = xml.attribute("path-in-package");
				base = cutBase(base, exp);
				map[exp] = base;
			}
			return map;
		}

		private static function cutBase(base : String, exp : String) : String {
			var index : int = base.lastIndexOf(exp);
			if (index >= 0 && index + exp.length == base.length) {
				base = base.substring(0, index)
			} else {
				index = exp.lastIndexOf("/");
				if (index >= 0) {
					exp = exp.substring(0, index);
				}
				index = base.lastIndexOf(exp);
				if (index >= 0 && index + exp.length == base.length) {
					base = base.substring(0, index)
				}
			}
			return base;
		}

		public function get file() : File {
			return _file;
		}
	}
}
