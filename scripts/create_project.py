#!/usr/bin/env python3
"""Regenerates the Xcode project references for the checked-in Swift sources."""
from pathlib import Path
import hashlib

root = Path(__file__).resolve().parent.parent
proj = root / 'AustinsBlockBlast.xcodeproj'
proj.mkdir(exist_ok=True)
source_names = [
    'AustinsBlockBlastApp.swift',
    'Core/GameCore.swift',
    'Core/GameStore.swift',
    'Views/Theme.swift',
    'Views/HomeScreen.swift',
    'Views/DailyChallengesScreen.swift',
    'Views/GameScreen.swift',
]

def uid(label):
    return hashlib.sha256(('AustinBlocks:' + label).encode()).hexdigest()[:24].upper()

rootgroup=uid('rootgroup')
sourcegroup=uid('sourcegroup')
coregroup=uid('coregroup')
viewgroup=uid('viewgroup')
productgroup=uid('productgroup')
project=uid('project')
target=uid('target')
product=uid('product')
sourcesphase=uid('sourcesphase')
resourcesphase=uid('resourcesphase')
frameworksphase=uid('frameworksphase')
projectconfig=uid('projectconfig')
targetconfig=uid('targetconfig')
pdebug=uid('pdebug')
prelease=uid('prelease')
tdebug=uid('tdebug')
trelease=uid('trelease')
assetref=uid('assets')
assetbuild=uid('assetsbuild')

refs = {file: uid('fileref:'+file) for file in source_names}
builds = {file: uid('build:'+file) for file in source_names}

text = '''// !$*UTF8*$!
{
    archiveVersion = 1;
    classes = {};
    objectVersion = 56;
    objects = {
/* Begin PBXBuildFile section */
'''
for file in source_names:
    text += f'        {builds[file]} /* {Path(file).name} in Sources */ = {{isa = PBXBuildFile; fileRef = {refs[file]} /* {Path(file).name} */; }};\n'
text += f'        {assetbuild} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assetref} /* Assets.xcassets */; }};\n'
text += '''/* End PBXBuildFile section */

/* Begin PBXFileReference section */
'''
for file in source_names:
    text += f'        {refs[file]} /* {Path(file).name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {Path(file).name}; sourceTree = "<group>"; }};\n'
text += f'''        {assetref} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};
        {product} /* AustinsBlockBlast.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = AustinsBlockBlast.app; sourceTree = BUILT_PRODUCTS_DIR; }};
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
        {frameworksphase} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
        {rootgroup} = {{isa = PBXGroup; children = ({sourcegroup} /* AustinsBlockBlast */, {productgroup} /* Products */, ); sourceTree = "<group>"; }};
        {sourcegroup} /* AustinsBlockBlast */ = {{isa = PBXGroup; children = (
            {refs['AustinsBlockBlastApp.swift']} /* AustinsBlockBlastApp.swift */,
            {coregroup} /* Core */,
            {viewgroup} /* Views */,
            {assetref} /* Assets.xcassets */,
        ); path = AustinsBlockBlast; sourceTree = "<group>"; }};
        {coregroup} /* Core */ = {{isa = PBXGroup; children = (
            {refs['Core/GameCore.swift']} /* GameCore.swift */,
            {refs['Core/GameStore.swift']} /* GameStore.swift */,
        ); path = Core; sourceTree = "<group>"; }};
        {viewgroup} /* Views */ = {{isa = PBXGroup; children = (
            {refs['Views/Theme.swift']} /* Theme.swift */,
            {refs['Views/HomeScreen.swift']} /* HomeScreen.swift */,
            {refs['Views/DailyChallengesScreen.swift']} /* DailyChallengesScreen.swift */,
            {refs['Views/GameScreen.swift']} /* GameScreen.swift */,
        ); path = Views; sourceTree = "<group>"; }};
        {productgroup} /* Products */ = {{isa = PBXGroup; children = ({product} /* AustinsBlockBlast.app */, ); name = Products; sourceTree = "<group>"; }};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
        {target} /* AustinsBlockBlast */ = {{
            isa = PBXNativeTarget;
            buildConfigurationList = {targetconfig} /* Build configuration list for PBXNativeTarget "AustinsBlockBlast" */;
            buildPhases = ({sourcesphase} /* Sources */, {frameworksphase} /* Frameworks */, {resourcesphase} /* Resources */, );
            buildRules = ();
            dependencies = ();
            name = AustinsBlockBlast;
            productName = AustinsBlockBlast;
            productReference = {product} /* AustinsBlockBlast.app */;
            productType = "com.apple.product-type.application";
        }};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
        {project} /* Project object */ = {{
            isa = PBXProject;
            attributes = {{ BuildIndependentTargetsInParallel = 1; LastUpgradeCheck = 1600; TargetAttributes = {{ {target} = {{ CreatedOnToolsVersion = 16.0; }}; }}; }};
            buildConfigurationList = {projectconfig} /* Build configuration list for PBXProject "AustinsBlockBlast" */;
            compatibilityVersion = "Xcode 14.0";
            developmentRegion = en;
            hasScannedForEncodings = 0;
            knownRegions = (en, Base, );
            mainGroup = {rootgroup};
            productRefGroup = {productgroup} /* Products */;
            projectDirPath = "";
            projectRoot = "";
            targets = ({target} /* AustinsBlockBlast */, );
        }};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
        {resourcesphase} /* Resources */ = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({assetbuild} /* Assets.xcassets in Resources */, ); runOnlyForDeploymentPostprocessing = 0; }};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
        {sourcesphase} /* Sources */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (
'''
for file in source_names:
    text += f'            {builds[file]} /* {Path(file).name} in Sources */,\n'
text += f'''        ); runOnlyForDeploymentPostprocessing = 0; }};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
'''
project_common = '''
                CLANG_ENABLE_MODULES = YES;
                CLANG_ENABLE_OBJC_ARC = YES;
                IPHONEOS_DEPLOYMENT_TARGET = 16.0;
                SDKROOT = iphoneos;
                SWIFT_VERSION = 5.0;
                TARGETED_DEVICE_FAMILY = 1;
'''
for cid, name in ((pdebug, 'Debug'), (prelease, 'Release')):
    settings = project_common
    if name=='Debug':
        settings += '                DEBUG_INFORMATION_FORMAT = dwarf;\n                ENABLE_TESTABILITY = YES;\n                SWIFT_OPTIMIZATION_LEVEL = "-Onone";\n'
    else:
        settings += '                DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";\n                SWIFT_COMPILATION_MODE = wholemodule;\n'
    text += f'''        {cid} /* {name} */ = {{isa = XCBuildConfiguration; buildSettings = {{{settings}            }}; name = {name}; }};
'''
target_common = '''
                ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
                CODE_SIGN_STYLE = Automatic;
                GENERATE_INFOPLIST_FILE = YES;
                INFOPLIST_KEY_CFBundleDisplayName = "Austins BlockBlast";
                INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.games";
                INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
                INFOPLIST_KEY_UILaunchScreen_Generation = YES;
                INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait";
                IPHONEOS_DEPLOYMENT_TARGET = 16.0;
                PRODUCT_BUNDLE_IDENTIFIER = dev.austins.blockblast;
                PRODUCT_NAME = "$(TARGET_NAME)";
                SWIFT_EMIT_LOC_STRINGS = YES;
                SWIFT_VERSION = 5.0;
                TARGETED_DEVICE_FAMILY = 1;
'''
for cid, name in ((tdebug, 'Debug'), (trelease, 'Release')):
    text += f'''        {cid} /* {name} */ = {{isa = XCBuildConfiguration; buildSettings = {{{target_common}            }}; name = {name}; }};
'''
text += f'''/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
        {projectconfig} /* Build configuration list for PBXProject "AustinsBlockBlast" */ = {{isa = XCConfigurationList; buildConfigurations = ({pdebug} /* Debug */, {prelease} /* Release */, ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};
        {targetconfig} /* Build configuration list for PBXNativeTarget "AustinsBlockBlast" */ = {{isa = XCConfigurationList; buildConfigurations = ({tdebug} /* Debug */, {trelease} /* Release */, ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};
/* End XCConfigurationList section */
    }};
    rootObject = {project} /* Project object */;
}}
'''
(proj / 'project.pbxproj').write_text(text)

scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.7">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
    <BuildActionEntries>
      <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
        <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="AustinsBlockBlast.app" BlueprintName="AustinsBlockBlast" ReferencedContainer="container:AustinsBlockBlast.xcodeproj"/>
      </BuildActionEntry>
    </BuildActionEntries>
  </BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"/>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
    <BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="AustinsBlockBlast.app" BlueprintName="AustinsBlockBlast" ReferencedContainer="container:AustinsBlockBlast.xcodeproj"/></BuildableProductRunnable>
  </LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"/>
  <AnalyzeAction buildConfiguration="Debug"/>
  <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
'''
schemedir = proj/'xcshareddata'/'xcschemes'
schemedir.mkdir(parents=True, exist_ok=True)
(schemedir/'AustinsBlockBlast.xcscheme').write_text(scheme)
print('Generated', proj/'project.pbxproj')
