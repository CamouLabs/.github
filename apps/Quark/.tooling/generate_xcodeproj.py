#!/usr/bin/env python3
"""Regenerate Quark.xcodeproj from the source tree.

The project file is checked in so the app opens with a double-click, but it is
generated rather than hand-edited: object IDs are derived from file paths, so
adding a Swift file and re-running this produces a minimal, readable diff
instead of a scrambled pbxproj. Mirrors what project.yml describes, for anyone
who would rather run XcodeGen.

    python3 .tooling/generate_xcodeproj.py
"""

from __future__ import annotations

import hashlib
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE_DIR = ROOT / "Quark"
PROJECT = ROOT / "Quark.xcodeproj"

APP_NAME = "Quark"
DISPLAY_NAME = "Quark - Learn STEM"
BUNDLE_ID = "com.camoulabs.Quark"
DEPLOYMENT_TARGET = "26.0"
MARKETING_VERSION = "1.0"
SWIFT_VERSION = "5.0"

TAB = "\t"


def oid(*parts: str) -> str:
    """Stable 24-character hex object ID, the shape Xcode expects."""
    digest = hashlib.md5("::".join(parts).encode("utf-8")).hexdigest()
    return digest[:24].upper()


def swift_sources() -> list[Path]:
    found = [
        path.relative_to(SOURCE_DIR)
        for path in sorted(SOURCE_DIR.rglob("*.swift"))
    ]
    if not found:
        raise SystemExit(f"no Swift sources under {SOURCE_DIR}")
    return found


def group_tree(paths: list[Path]) -> dict:
    """Nested dict of directory name -> subtree, with "" holding leaf files."""
    tree: dict = {"": []}
    for path in paths:
        node = tree
        for part in path.parts[:-1]:
            node = node.setdefault(part, {"": []})
        node[""].append(path)
    return tree


def emit_file_references(paths: list[Path], extras: list[str]) -> list[str]:
    lines = []
    for path in paths:
        lines.append(
            f'{TAB}{TAB}{oid("file", str(path))} /* {path.name} */ = '
            f"{{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; "
            f'path = {path.name}; sourceTree = "<group>"; }};'
        )
    for name in extras:
        lines.append(
            f'{TAB}{TAB}{oid("file", name)} /* {name} */ = '
            f"{{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; "
            f'path = {name}; sourceTree = "<group>"; }};'
        )
    lines.append(
        f'{TAB}{TAB}{oid("product")} /* {DISPLAY_NAME}.app */ = '
        f"{{isa = PBXFileReference; explicitFileType = wrapper.application; "
        f'includeInIndex = 0; path = "{DISPLAY_NAME}.app"; sourceTree = BUILT_PRODUCTS_DIR; }};'
    )
    return lines


def emit_build_files(paths: list[Path], extras: list[str]) -> list[str]:
    lines = []
    for path in paths:
        lines.append(
            f'{TAB}{TAB}{oid("build", str(path))} /* {path.name} in Sources */ = '
            f'{{isa = PBXBuildFile; fileRef = {oid("file", str(path))} '
            f"/* {path.name} */; }};"
        )
    for name in extras:
        lines.append(
            f'{TAB}{TAB}{oid("build", name)} /* {name} in Resources */ = '
            f'{{isa = PBXBuildFile; fileRef = {oid("file", name)} /* {name} */; }};'
        )
    return lines


def emit_groups(tree: dict, path_parts: tuple[str, ...], extras: list[str]) -> list[str]:
    """Depth-first so children are declared before the parent that lists them."""
    lines: list[str] = []
    children: list[str] = []

    for name in sorted(key for key in tree if key != ""):
        lines.extend(emit_groups(tree[name], path_parts + (name,), []))
        group_id = oid("group", "/".join(path_parts + (name,)))
        children.append(f"{TAB}{TAB}{TAB}{TAB}{group_id} /* {name} */,")

    for extra in extras:
        children.append(f'{TAB}{TAB}{TAB}{TAB}{oid("file", extra)} /* {extra} */,')

    for file_path in sorted(tree[""], key=lambda item: item.name):
        children.append(
            f'{TAB}{TAB}{TAB}{TAB}{oid("file", str(file_path))} /* {file_path.name} */,'
        )

    group_id = oid("group", "/".join(path_parts))
    name = path_parts[-1]
    lines.extend(
        [
            f"{TAB}{TAB}{group_id} /* {name} */ = {{",
            f"{TAB}{TAB}{TAB}isa = PBXGroup;",
            f"{TAB}{TAB}{TAB}children = (",
            *children,
            f"{TAB}{TAB}{TAB});",
            f"{TAB}{TAB}{TAB}path = {name};",
            f'{TAB}{TAB}{TAB}sourceTree = "<group>";',
            f"{TAB}{TAB}}};",
        ]
    )
    return lines


SHARED_BUILD_SETTINGS = [
    "ALWAYS_SEARCH_USER_PATHS = NO",
    "CLANG_ANALYZER_NONNULL = YES",
    "CLANG_ENABLE_MODULES = YES",
    "CLANG_ENABLE_OBJC_ARC = YES",
    "CLANG_WARN_BOOL_CONVERSION = YES",
    "CLANG_WARN_CONSTANT_CONVERSION = YES",
    "CLANG_WARN_DOCUMENTATION_COMMENTS = YES",
    "CLANG_WARN_EMPTY_BODY = YES",
    "CLANG_WARN_INFINITE_RECURSION = YES",
    "CLANG_WARN_INT_CONVERSION = YES",
    "CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE",
    "CLANG_WARN_UNREACHABLE_CODE = YES",
    "ENABLE_STRICT_OBJC_MSGSEND = YES",
    "GCC_NO_COMMON_BLOCKS = YES",
    "GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR",
    "GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE",
    "GCC_WARN_UNUSED_FUNCTION = YES",
    "GCC_WARN_UNUSED_VARIABLE = YES",
    f"IPHONEOS_DEPLOYMENT_TARGET = {DEPLOYMENT_TARGET}",
    'PRODUCT_NAME = "$(TARGET_NAME)"',
    "SDKROOT = iphoneos",
    f"SWIFT_VERSION = {SWIFT_VERSION}",
]

TARGET_BUILD_SETTINGS = [
    "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon",
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor",
    "CURRENT_PROJECT_VERSION = 1",
    "GENERATE_INFOPLIST_FILE = YES",
    f'INFOPLIST_KEY_CFBundleDisplayName = "{DISPLAY_NAME}"',
    'INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.education"',
    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES",
    "INFOPLIST_KEY_UILaunchScreen_Generation = YES",
    'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"',
    'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait"',
    f"MARKETING_VERSION = {MARKETING_VERSION}",
    f"PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID}",
    f'PRODUCT_NAME = "{DISPLAY_NAME}"',
    "SDKROOT = iphoneos",
    "SWIFT_EMIT_LOC_STRINGS = YES",
    'TARGETED_DEVICE_FAMILY = "1,2"',
]


def settings_block(entries: list[str], indent: int) -> list[str]:
    pad = TAB * indent
    return [f"{pad}{entry};" for entry in sorted(entries)]


def build_configuration(name: str, entries: list[str], key: str) -> list[str]:
    return [
        f'{TAB}{TAB}{oid("config", key, name)} /* {name} */ = {{',
        f"{TAB}{TAB}{TAB}isa = XCBuildConfiguration;",
        f"{TAB}{TAB}{TAB}buildSettings = {{",
        *settings_block(entries, 4),
        f"{TAB}{TAB}{TAB}}};",
        f"{TAB}{TAB}{TAB}name = {name};",
        f"{TAB}{TAB}}};",
    ]


def configuration_list(key: str, label: str) -> list[str]:
    return [
        f'{TAB}{TAB}{oid("configlist", key)} /* Build configuration list for {label} */ = {{',
        f"{TAB}{TAB}{TAB}isa = XCConfigurationList;",
        f"{TAB}{TAB}{TAB}buildConfigurations = (",
        f'{TAB}{TAB}{TAB}{TAB}{oid("config", key, "Debug")} /* Debug */,',
        f'{TAB}{TAB}{TAB}{TAB}{oid("config", key, "Release")} /* Release */,',
        f"{TAB}{TAB}{TAB});",
        f"{TAB}{TAB}{TAB}defaultConfigurationIsVisible = 0;",
        f"{TAB}{TAB}{TAB}defaultConfigurationName = Release;",
        f"{TAB}{TAB}}};",
    ]


def render() -> str:
    sources = swift_sources()
    extras = ["Assets.xcassets"]
    tree = group_tree(sources)

    project_debug = SHARED_BUILD_SETTINGS + [
        "DEBUG_INFORMATION_FORMAT = dwarf",
        "ENABLE_TESTABILITY = YES",
        "GCC_OPTIMIZATION_LEVEL = 0",
        'GCC_PREPROCESSOR_DEFINITIONS = ("$(inherited)", "DEBUG=1")',
        "MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE",
        "ONLY_ACTIVE_ARCH = YES",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG",
        'SWIFT_OPTIMIZATION_LEVEL = "-Onone"',
    ]
    project_release = SHARED_BUILD_SETTINGS + [
        'DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym"',
        "ENABLE_NS_ASSERTIONS = NO",
        "MTL_ENABLE_DEBUG_INFO = NO",
        "SWIFT_COMPILATION_MODE = wholemodule",
        'SWIFT_OPTIMIZATION_LEVEL = "-O"',
        "VALIDATE_PRODUCT = YES",
    ]
    target_settings = TARGET_BUILD_SETTINGS + [
        'LD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks")'
    ]

    lines: list[str] = [
        "// !$*UTF8*$!",
        "{",
        f"{TAB}archiveVersion = 1;",
        f"{TAB}classes = {{",
        f"{TAB}}};",
        f"{TAB}objectVersion = 63;",
        f"{TAB}objects = {{",
        "",
        "/* Begin PBXBuildFile section */",
        *emit_build_files(sources, extras),
        "/* End PBXBuildFile section */",
        "",
        "/* Begin PBXFileReference section */",
        *emit_file_references(sources, extras),
        "/* End PBXFileReference section */",
        "",
        "/* Begin PBXGroup section */",
        *emit_groups(tree, (APP_NAME,), extras),
        f'{TAB}{TAB}{oid("group", "root")} = {{',
        f"{TAB}{TAB}{TAB}isa = PBXGroup;",
        f"{TAB}{TAB}{TAB}children = (",
        f'{TAB}{TAB}{TAB}{TAB}{oid("group", APP_NAME)} /* {APP_NAME} */,',
        f'{TAB}{TAB}{TAB}{TAB}{oid("group", "products")} /* Products */,',
        f"{TAB}{TAB}{TAB});",
        f'{TAB}{TAB}{TAB}sourceTree = "<group>";',
        f"{TAB}{TAB}}};",
        f'{TAB}{TAB}{oid("group", "products")} /* Products */ = {{',
        f"{TAB}{TAB}{TAB}isa = PBXGroup;",
        f"{TAB}{TAB}{TAB}children = (",
        f'{TAB}{TAB}{TAB}{TAB}{oid("product")} /* {DISPLAY_NAME}.app */,',
        f"{TAB}{TAB}{TAB});",
        f"{TAB}{TAB}{TAB}name = Products;",
        f'{TAB}{TAB}{TAB}sourceTree = "<group>";',
        f"{TAB}{TAB}}};",
        "/* End PBXGroup section */",
        "",
        "/* Begin PBXNativeTarget section */",
        f'{TAB}{TAB}{oid("target")} /* {APP_NAME} */ = {{',
        f"{TAB}{TAB}{TAB}isa = PBXNativeTarget;",
        f'{TAB}{TAB}{TAB}buildConfigurationList = {oid("configlist", "target")} '
        f'/* Build configuration list for PBXNativeTarget "{APP_NAME}" */;',
        f"{TAB}{TAB}{TAB}buildPhases = (",
        f'{TAB}{TAB}{TAB}{TAB}{oid("phase", "sources")} /* Sources */,',
        f'{TAB}{TAB}{TAB}{TAB}{oid("phase", "resources")} /* Resources */,',
        f"{TAB}{TAB}{TAB});",
        f"{TAB}{TAB}{TAB}buildRules = (",
        f"{TAB}{TAB}{TAB});",
        f"{TAB}{TAB}{TAB}dependencies = (",
        f"{TAB}{TAB}{TAB});",
        f"{TAB}{TAB}{TAB}name = {APP_NAME};",
        f"{TAB}{TAB}{TAB}productName = {APP_NAME};",
        f'{TAB}{TAB}{TAB}productReference = {oid("product")} /* {DISPLAY_NAME}.app */;',
        f'{TAB}{TAB}{TAB}productType = "com.apple.product-type.application";',
        f"{TAB}{TAB}}};",
        "/* End PBXNativeTarget section */",
        "",
        "/* Begin PBXProject section */",
        f'{TAB}{TAB}{oid("project")} /* Project object */ = {{',
        f"{TAB}{TAB}{TAB}isa = PBXProject;",
        f"{TAB}{TAB}{TAB}attributes = {{",
        f"{TAB}{TAB}{TAB}{TAB}BuildIndependentTargetsInParallel = YES;",
        f"{TAB}{TAB}{TAB}{TAB}LastUpgradeCheck = 1600;",
        f"{TAB}{TAB}{TAB}}};",
        f'{TAB}{TAB}{TAB}buildConfigurationList = {oid("configlist", "project")} '
        f'/* Build configuration list for PBXProject "{APP_NAME}" */;',
        f'{TAB}{TAB}{TAB}compatibilityVersion = "Xcode 15.0";',
        f"{TAB}{TAB}{TAB}developmentRegion = en;",
        f"{TAB}{TAB}{TAB}hasScannedForEncodings = 0;",
        f"{TAB}{TAB}{TAB}knownRegions = (",
        f"{TAB}{TAB}{TAB}{TAB}Base,",
        f"{TAB}{TAB}{TAB}{TAB}en,",
        f"{TAB}{TAB}{TAB});",
        f'{TAB}{TAB}{TAB}mainGroup = {oid("group", "root")};',
        f'{TAB}{TAB}{TAB}productRefGroup = {oid("group", "products")} /* Products */;',
        f'{TAB}{TAB}{TAB}projectDirPath = "";',
        f'{TAB}{TAB}{TAB}projectRoot = "";',
        f"{TAB}{TAB}{TAB}targets = (",
        f'{TAB}{TAB}{TAB}{TAB}{oid("target")} /* {APP_NAME} */,',
        f"{TAB}{TAB}{TAB});",
        f"{TAB}{TAB}}};",
        "/* End PBXProject section */",
        "",
        "/* Begin PBXResourcesBuildPhase section */",
        f'{TAB}{TAB}{oid("phase", "resources")} /* Resources */ = {{',
        f"{TAB}{TAB}{TAB}isa = PBXResourcesBuildPhase;",
        f"{TAB}{TAB}{TAB}buildActionMask = 2147483647;",
        f"{TAB}{TAB}{TAB}files = (",
        *[
            f'{TAB}{TAB}{TAB}{TAB}{oid("build", name)} /* {name} in Resources */,'
            for name in extras
        ],
        f"{TAB}{TAB}{TAB});",
        f"{TAB}{TAB}{TAB}runOnlyForDeploymentPostprocessing = 0;",
        f"{TAB}{TAB}}};",
        "/* End PBXResourcesBuildPhase section */",
        "",
        "/* Begin PBXSourcesBuildPhase section */",
        f'{TAB}{TAB}{oid("phase", "sources")} /* Sources */ = {{',
        f"{TAB}{TAB}{TAB}isa = PBXSourcesBuildPhase;",
        f"{TAB}{TAB}{TAB}buildActionMask = 2147483647;",
        f"{TAB}{TAB}{TAB}files = (",
        *[
            f'{TAB}{TAB}{TAB}{TAB}{oid("build", str(path))} /* {path.name} in Sources */,'
            for path in sources
        ],
        f"{TAB}{TAB}{TAB});",
        f"{TAB}{TAB}{TAB}runOnlyForDeploymentPostprocessing = 0;",
        f"{TAB}{TAB}}};",
        "/* End PBXSourcesBuildPhase section */",
        "",
        "/* Begin XCBuildConfiguration section */",
        *build_configuration("Debug", project_debug, "project"),
        *build_configuration("Release", project_release, "project"),
        *build_configuration("Debug", target_settings, "target"),
        *build_configuration("Release", target_settings, "target"),
        "/* End XCBuildConfiguration section */",
        "",
        "/* Begin XCConfigurationList section */",
        *configuration_list("project", f'PBXProject "{APP_NAME}"'),
        *configuration_list("target", f'PBXNativeTarget "{APP_NAME}"'),
        "/* End XCConfigurationList section */",
        f"{TAB}}};",
        f'{TAB}rootObject = {oid("project")} /* Project object */;',
        "}",
        "",
    ]
    return "\n".join(lines)


WORKSPACE_DATA = """<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
"""


def scheme() -> str:
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{oid("target")}"
               BuildableName = "{DISPLAY_NAME}.app"
               BlueprintName = "{APP_NAME}"
               ReferencedContainer = "container:{APP_NAME}.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{oid("target")}"
            BuildableName = "{DISPLAY_NAME}.app"
            BlueprintName = "{APP_NAME}"
            ReferencedContainer = "container:{APP_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{oid("target")}"
            BuildableName = "{DISPLAY_NAME}.app"
            BlueprintName = "{APP_NAME}"
            ReferencedContainer = "container:{APP_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""


def write(path: Path, contents: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(contents, encoding="utf-8")
    print(f"wrote {path.relative_to(ROOT)}")


def main() -> None:
    write(PROJECT / "project.pbxproj", render())
    write(PROJECT / "project.xcworkspace" / "contents.xcworkspacedata", WORKSPACE_DATA)
    write(PROJECT / "xcshareddata" / "xcschemes" / f"{APP_NAME}.xcscheme", scheme())
    count = len(swift_sources())
    print(f"{count} Swift files in the {APP_NAME} target")


if __name__ == "__main__":
    os.chdir(ROOT)
    main()
