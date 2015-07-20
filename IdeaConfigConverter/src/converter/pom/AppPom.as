package converter.pom {
	import converter.StringUtil;
	import converter.dom.Module;
	import converter.dom.Project;

	import flash.filesystem.File;

	public class AppPom extends BasePom implements IPom {

		[Embed(source="/../gradle/app.gradle", mimeType="application/octet-stream")]
		private static const POM_DATA : Class;
		private static const POM : String = String(new POM_DATA);

		public function AppPom(project : Project, iml : Module) {
			super(project, iml);
		}

		override public function getData() : String {
			var platform : String = project.projectModuleRoot.platform;
			var template : String = POM;
			template = replaceBasicVars(template);
			template = addMainClass(template);
			template = addStuffToResultXML(template);
			template = StringUtil.replace(template, "${type}", iml.targetPlatform == Module.TARGET_PLATFORM_MOBILE ? "mobile" : "swf");
			template = StringUtil.replace(template, "${source.certificate}", iml.pomDirectory.getRelativePath(iml.getCerteficate(platform), true));
			template = StringUtil.replace(template, "${source.provision}", iml.pomDirectory.getRelativePath(iml.provision, true));
			template = StringUtil.replace(template, "${source.keystoreType}", iml.getKeystoreType(platform));
			template = StringUtil.replace(template, "${source.descriptor}", iml.pomDirectory.getRelativePath(iml.getDescriptor(platform), true));
			template = StringUtil.replace(template, "${storepass}", project.projectModuleRoot.storepass);
			template = StringUtil.replace(template, "${mobile.resources}", formatMobileResources(iml.getMobileResources(platform)));
			return template;
		}

		private function formatMobileResources(mobileResources : Object) : String {
			var result : Array = [];
			for (var res : String in mobileResources) {
				result.push("'-C', '" + mobileResources[res] + "', '" + res + "'");
			}
			result.sort();
			return result.join(",\n");
		}

		private function addMainClass(template : String) : String {
			var splitted : Array = iml.mainClass.split(".");
			var name : String = splitted.pop();
			var main : String = splitted.join("/");
			if (main) {
				main += "/";
			}
			var possibleMXML : File = iml.directory.resolvePath(iml.sourceDirectoryURLs[0]).resolvePath(main).resolvePath(name + ".mxml");
			name += possibleMXML.exists ? ".mxml" : ".as";
			template = StringUtil.replaceByMap(template, {
				"${source.file.directory}": main,
				"${source.file.name}": name
			});
			return template;
		}
	}
}
