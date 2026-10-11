#!/usr/bin/env python3
"""Generate the dependency-free iOS target; preserves source and ignores user settings."""
from pathlib import Path
import hashlib

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "Kairos.xcodeproj"
PROJECT.mkdir(exist_ok=True)

def ident(name):
    return hashlib.sha256(name.encode()).hexdigest()[:24].upper()

def item(name, value):
    return f"\t\t{ident(name)} = {{ {value} }};"

sources = sorted((ROOT / "Kairos").glob("*.swift"))
objects = []
for source in sources:
    objects.append(item("file-" + source.name, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{source.name}"; sourceTree = "<group>";'))
    objects.append(item("build-" + source.name, f'isa = PBXBuildFile; fileRef = {ident("file-" + source.name)};'))
children = " ".join(ident("file-" + source.name) + "," for source in sources)
builds = " ".join(ident("build-" + source.name) + "," for source in sources)
objects += [
    item("main", f'isa = PBXGroup; children = ({ident("sources-group")}, {ident("products")},); sourceTree = "<group>";'),
    item("sources-group", f'isa = PBXGroup; children = ({children}); path = Kairos; sourceTree = "<group>";'),
    item("products", f'isa = PBXGroup; children = ({ident("app")},); name = Products; sourceTree = "<group>";'),
    item("app", 'isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Kairos.app; sourceTree = BUILT_PRODUCTS_DIR;'),
    item("source-phase", f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({builds}); runOnlyForDeploymentPostprocessing = 0;'),
    item("framework-phase", 'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;'),
    item("resource-phase", 'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;'),
    item("project", f'''isa = PBXProject; attributes = {{ LastUpgradeCheck = 2700; TargetAttributes = {{ {ident("target")} = {{ CreatedOnToolsVersion = "27.0"; }}; }}; }};
            buildConfigurationList = {ident("project-configs")}; compatibilityVersion = "Xcode 14.0";
            developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base,);
            mainGroup = {ident("main")}; productRefGroup = {ident("products")}; projectDirPath = ""; projectRoot = "";
            targets = ({ident("target")},);'''),
    item("target", f'''isa = PBXNativeTarget; buildConfigurationList = {ident("target-configs")};
            buildPhases = ({ident("source-phase")}, {ident("framework-phase")}, {ident("resource-phase")},);
            buildRules = (); dependencies = (); name = Kairos; productName = Kairos; productReference = {ident("app")}; productType = "com.apple.product-type.application";'''),
]
for name, debug in [("Debug", True), ("Release", False)]:
    shared = '''CLANG_ENABLE_MODULES = YES; CLANG_ENABLE_OBJC_ARC = YES; GCC_C_LANGUAGE_STANDARD = gnu17;
            SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 17.0; SWIFT_VERSION = 5.0;'''
    objects.append(item("project-" + name, f'''isa = XCBuildConfiguration; name = {name}; buildSettings = {{ {shared}
            DEBUG_INFORMATION_FORMAT = {"dwarf" if debug else '"dwarf-with-dsym"'}; ENABLE_TESTABILITY = {"YES" if debug else "NO"};
            SWIFT_OPTIMIZATION_LEVEL = {"\"-Onone\"" if debug else '"-O"'};
            SWIFT_ACTIVE_COMPILATION_CONDITIONS = {"DEBUG" if debug else '""'}; }};'''))
    objects.append(item("target-" + name, f'''isa = XCBuildConfiguration; name = {name}; buildSettings = {{
            CODE_SIGN_STYLE = Automatic; CURRENT_PROJECT_VERSION = 1; MARKETING_VERSION = 0.1.0;
            PRODUCT_BUNDLE_IDENTIFIER = com.steffanhaskins.kairos; PRODUCT_NAME = "$(TARGET_NAME)";
            GENERATE_INFOPLIST_FILE = YES; INFOPLIST_KEY_CFBundleDisplayName = Kairos;
            INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO; INFOPLIST_KEY_UILaunchScreen_Generation = YES;
            INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
            INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
            INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
            SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"; TARGETED_DEVICE_FAMILY = "1,2";
            SUPPORTS_MACCATALYST = NO; SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO; SWIFT_EMIT_LOC_STRINGS = YES;
            LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks";
            }};'''))
for kind in ("project", "target"):
    objects.append(item(kind + "-configs", f'isa = XCConfigurationList; buildConfigurations = ({ident(kind + "-Debug")}, {ident(kind + "-Release")},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;'))
content = '// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {};\n\tobjectVersion = 56;\n\tobjects = {\n' + '\n'.join(objects) + '\n\t};\n\trootObject = ' + ident("project") + ';\n}\n'
(PROJECT / "project.pbxproj").write_text(content)
schemes = PROJECT / "xcshareddata/xcschemes"
schemes.mkdir(parents=True, exist_ok=True)
(schemes / "Kairos.xcscheme").write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.3">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ident("target")}" BuildableName="Kairos.app" BlueprintName="Kairos" ReferencedContainer="container:Kairos.xcodeproj"/></BuildActionEntry></BuildActionEntries></BuildAction>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ident("target")}" BuildableName="Kairos.app" BlueprintName="Kairos" ReferencedContainer="container:Kairos.xcodeproj"/></BuildableProductRunnable></LaunchAction>
 <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugServiceExtension="internal"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ident("target")}" BuildableName="Kairos.app" BlueprintName="Kairos" ReferencedContainer="container:Kairos.xcodeproj"/></BuildableProductRunnable></ProfileAction>
 <AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
print(f"Generated {PROJECT} with {len(sources)} Swift sources")
