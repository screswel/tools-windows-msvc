
# GNUstep Windows MSVC Toolchain

[![CI](https://github.com/gnustep/tools-windows-msvc/actions/workflows/ci.yml/badge.svg)](https://github.com/gnustep/tools-windows-msvc/actions/workflows/ci.yml?query=branch%3Amaster)

This project comprises a collection of scripts to build a modern GNUstep toolchain, with support for blocks and Automatic Reference Counting (ARC), using LLVM/Clang and the Visual Studio toolchain. The toolchain can be used to integrate Objective-C code in any Windows app, including Visual Studio projects using LLVM/Clang (see below), without using MinGW.


## Libraries

The toolchain currently consists of the following libraries, many now provided via a fork of Microsoft's VCPKG at https://github.com/screswel/vcpkg:

- [GNUstep Base Library](https://github.com/gnustep/libs-base) (Foundation)
- [GNUstep CoreBase Library](https://github.com/gnustep/libs-corebase) (CoreFoundation)
- [libobjc2](vcpkg install libobjc2:x64-windows) (using gnustep-2.0 runtime)
- [libdispatch](vcpkg install libdispatch:x64-windows) (official Apple release from the Swift Core Libraries)
- [libffi](vcpkg install libffi:x64-windows)
- [libiconv](vcpkg install libiconv:x64-windows)
- [libxml2](vcpkg install libxml2:x64-windows)
- [libxslt](vcpkg install libxslt:x64-windows)
- [ICU](vcpkg install icu:x64-windows)


## Installation

To install a pre-built release, download it from [the releases on GitHub](https://github.com/gnustep/tools-windows-msvc/releases) and unpack it into into `C:\GNUstep` (this location is only required if you plan on using the `gnustep-config` script, otherwise any location will work).

You should end up with the folders `C:\GNUstep\x64\Debug` and `C:\GNUstep\x64\Release` when using the x64 toolchain. The explanations below and the example project assume this installation location.


## Using the Toolchain from the Command Line

Building and linking Objective-C code using the toolchain and `clang` requires VCPKG and a number of compiler and linker flags.

Clone and bootstrap a fork of Microsoft's VCPKG, from a Visual Studio command prompt:

    mkdir C:\src
    cd C:\src
    git clone https://github.com/screswel/vcpkg
    .\bootstrap-vcpkg.bat -disableMetrics
    .\vcpkg install libffi:x64-windows
    .\vcpkg install libiconv:x64-windows
    .\vcpkg install libxml2:x64-windows
    .\vcpkg install libxslt:x64-windows
    .\vcpkg install icu:x64-windows
    .\vcpkg install libobjc2:x64-windows
    .\vcpkg install libdispatch:x64-windows

When building in a Bash environment (like an MSYS2 shell), the `gnustep-config` tool can be used to query the necessary flags for building and linking:

    # add gnustep-config directory to PATH (use Debug or Release version)
    export PATH="$PATH:/c/GNUstep/x64/Debug/bin/"
    
    # build test.m to produce an object file test.o
    clang `gnustep-config --objc-flags` -c test.m
    
    # link object file into executable
    clang `gnustep-config --base-libs` -ldispatch -o test.exe test.o

The  `clang-cl` driver can also be used to build Objective-C code, but requires prefixing some of the options using the `-Xclang` modifier to pass them directly to Clang:

    # build test.m to produce an object file test.obj
    clang-cl -I C:\GNUstep\x64\Debug\include -fobjc-runtime=gnustep-2.0 -Xclang -fexceptions -Xclang -fobjc-exceptions -fblocks -DGNUSTEP -DGNUSTEP_WITH_DLL -DGNUSTEP_RUNTIME=1 -D_NONFRAGILE_ABI=1 -D_NATIVE_OBJC_EXCEPTIONS /MDd /c test.m
    
    # link object file into executable
    clang-cl test.obj gnustep-base.lib objc.lib dispatch.lib /MDd -o test.exe

Specify `/MDd` for debug builds, and `/MD` for release builds, in order to link against the same run-time libraries as the DLLs in `C:\GNUstep\x64\Debug` and `C:\GNUstep\x64\Release` respectively.

Note that the `GNUSTEP_WITH_DLL` definition is always required to enable annotation of the Objective-C objects defined in the GNUstep Base DLL with `__declspec(dllexport)`.


## Using the Toolchain in Visual Studio

The [examples/ObjCWin32](examples/ObjCWin32) folder contains a Visual Studio project that is set up with support for Objective-C.

Following are instructions to set up your own project, or add Objective-C support to an existing Win32 Visual Studio project.

### Create the Project

Launch Visual Studio, select "Create a new project", and select a project template that is compatible with C++/Win32, e.g. Console App, Windows Desktop Application, Static Library, Dynamic-Link Library (DLL). In the following we assume we are building a Console App.

Choose a name for the project and create the project. In this example, we choose ObjCHello.

### Edit the Project

#### Edit Project Properties

1. Right-click the project in Solution Explorer and select "Properties".
2. In "General" change "Platform Toolset" to "LLVM (clang-cl)". MSVC does not support compiling Objective-C source files.
3. In "VC++ Directories" add the following for toolchain headers and libraries to be found: 
    * Include Directories: `C:\GNUstep\$(LibrariesArchitecture)\$(Configuration)\include`
    * Library Directories: `C:\GNUstep\$(LibrariesArchitecture)\$(Configuration)\lib`
4. Set required preprocessor definitions in C/C++ > Preprocessor > Preprocessor Definitions:  
  `GNUSTEP;GNUSTEP_WITH_DLL;GNUSTEP_RUNTIME=1;_NONFRAGILE_ABI=1;_NATIVE_OBJC_EXCEPTIONS`
5. Add required compiler options in C/C++ > Command Line > Additional Options:  
  `-fobjc-runtime=gnustep-2.0 -Xclang -fexceptions -Xclang -fobjc-exceptions -fblocks -Xclang -fobjc-arc`  
  Remove the last two options (`-Xclang -fobjc-arc`) if you don't want to use Automatic Reference Counting (ARC).
6. Link required libraries in Linker > Input > Additional Dependencies:  
  `gnustep-base.lib;objc.lib;dispatch.lib`

#### Edit Project File

1. Right-click the project in Solution Explorer and select "Unload Project".
2. Double-click on the project again and to open the raw vcxproj file.
3. Above the last line `</Project>` add the following to copy the GNUstep DLLs to the output directory.
   ```
   <ItemGroup>
     <Content Include="C:\GNUstep\$(LibrariesArchitecture)\$(Configuration)\bin\*.dll">
       <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
       <TargetPath>%(Filename)%(Extension)</TargetPath>
     </Content>
   </ItemGroup>
   ```
4. Right click the project in Solution Explorer and select "Reload Project".

#### Edit Source File Properties

1. Right-click on the `ObjCHello.cpp` source file and rename it to `ObjCHello.m` (or `ObjCHello.mm` for Objective-C++).
2. Right-click on each Objective-C(++) file in the project and select "Properties".
3. In C/C++ > Advanced, clear the "Compile As" option.  
This means the file will be built as Objective-C(++) based on the file extension (by not setting `/TC`/`/TP` flags that otherwise cause the file to be built as C/C++ irrespective of its extension).

### Add Objective-C Code and Run

Now you can start writing your Objective-C code in the `ObjCHello.m` file. You can test the setup by replacing the content of the file with:

```objective-c
#include <Foundation/Foundation.h>

int main(int argc, char *argv[])
{
    NSLog(@"Hello Objective-C");
    return 0;
}
```

Place a breakpoint at the line `NSLog(@"Hello Objective-C");` and run from Visual Studio. You should see the breakpoint getting hit, and the log printed in the "Output" panel when you continue.


## Status and Known Issues

The toolchain is fully usable on x64. On x86, libdispatch is not available due to a [build error](https://bugs.swift.org/browse/SR-14314).

Note that GNUstep support for Windows is not as complete as on Unixes, and some [tests in GNUstep Base](https://github.com/gnustep/libs-base/actions/workflows/main.yml?query=branch%3Amaster) are still failing.


## Troubleshooting

### Compile Errors

* `'Foundation/Foundation.h' file not found`  
Please ensure that you correctly set "Include Directories".

* `#import of type library is an unsupported Microsoft feature`  
Please ensure that you have cleared the "Compile As" property of the file.

### Link Errors

* `cannot open input file 'gnustep-base.lib'`  
Please ensure that you correctly set "Library Directories".

* ` unresolved external symbol __objc_load referenced in function .objcv2_load_function`  
Please ensure that you added the required linking options in Linker > Input > Additional Dependencies.

* `relocation against symbol in discarded section: __start_.objcrt$SEL`  
Please ensure that you include some Objective-C code in your project. (This is currently required due to a [compiler/linker issue](https://github.com/llvm/llvm-project/issues/49025) when using the LLD linker. Alternatively you can use link.exe instead of LLD.)

### Runtime Errors

* `The code execution cannot proceed because gnustep-base-1_28.dll was not found. Reinstalling the program may fix this problem.`  
Please ensure that DLLs are copied to the output folder.


## Building the Toolchain

### Prerequisites

Building the toolchain require the following tools to be installed and available in the PATH. Their presence is verified when building the toolchain.

The MSYS2 installation is required to provide the Bash shell and Unix tools required to build some of the libraries, but no MinGW packages are needed. The Windows Clang installation is used to build all libraries.

**Windows tools**

- Visual Studio 2019 or 2022
- Clang (via Visual Studio or `choco install llvm`)
- CMake (via Visual Studio or `choco install cmake --installargs 'ADD_CMAKE_TO_PATH=System'`)
- Git (`choco install git`)
- Ninja (`choco install ninja`)
- MSYS2 (`choco install msys2`)

**Unix tools**

- Make
- Autoconf/Automake
- libtool
- pkg-config

These can be installed via Pacman inside a MSYS2 shell:  
`pacman -S --needed make autoconf automake libtool pkg-config`

Please make sure that you do _not_ have `gmake` installed in your MSYS2 environment, as it is not compatible but will be picked up by the project Makefiles. Running `which gmake` in MSYS2 should print "which: no gmake in ...".

### Building

Run the [build.bat](build.bat) script in either a x86 or x64 Native Tools Command Prompt from Visual Studio to build the toolchain for x86 or x64.

```
Usage: build.bat
  --prefix INSTALL_ROOT    Install toolchain into given directory (default: C:\GNUstep)
  --type Debug/Release     Build only the given build type (default: both)
  --only PHASE             Re-build only the given phase (e.g. "gnustep-base")
  --only-dependencies      Build only GNUstep dependencies
  --patches DIR            Apply additional patches from given directory
  -h, --help, /?           Print usage information and exit
```

For each of the libraries, the script automatically downloads the source via Git into the `src` subdirectory, builds, and installs it.

The toolchain is installed into `C:\GNUstep\[x86|x64]\[Debug|Release]`.
