/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest

import Basic
import PackageDescription4
import PackageDescription
import PackageModel
import Utility

@testable import PackageLoading

/// Tests for the handling of source layout conventions.
class PackageBuilderTests: XCTestCase {
    
    func testDotFilesAreIgnored() throws {
        let fs = InMemoryFileSystem(emptyFiles:
            "/.Bar.swift",
            "/Foo.swift")

        let name = "DotFilesAreIgnored"
        PackageBuilderTester(name, in: fs) { result in
            result.checkModule(name) { moduleResult in
                moduleResult.check(c99name: name, type: .library)
                moduleResult.checkSources(root: "/", paths: "Foo.swift")
            }
        }
    }

    func testResolvesSingleSwiftLibraryModule() throws {
        var fs = InMemoryFileSystem(emptyFiles:
            "/Foo.swift")

        let name = "SingleSwiftTarget"
        PackageBuilderTester(name, in: fs) { result in
            result.checkModule(name) { moduleResult in
                moduleResult.check(c99name: name, type: .library)
                moduleResult.checkSources(root: "/", paths: "Foo.swift")
            }
        }

        // Single swift target inside Sources.
        fs = InMemoryFileSystem(emptyFiles:
            "/Sources/Foo.swift",
            "/Sources/Bar.swift")

        PackageBuilderTester(name, in: fs) { result in
            result.checkModule(name) { moduleResult in
                moduleResult.check(c99name: name, type: .library)
                moduleResult.checkSources(root: "/Sources", paths: "Foo.swift", "Bar.swift")
            }
        }

        // Single swift target inside its own directory.
        fs = InMemoryFileSystem(emptyFiles:
            "/Sources/lib/Foo.swift",
            "/Sources/lib/Bar.swift")

        PackageBuilderTester(name, in: fs) { result in
            result.checkModule("lib") { moduleResult in
                moduleResult.check(c99name: "lib", type: .library)
                moduleResult.checkSources(root: "/Sources/lib", paths: "Foo.swift", "Bar.swift")
            }
        }
    }

    func testResolvesSystemModulePackage() throws {
        let fs = InMemoryFileSystem(emptyFiles:
            "/module.modulemap")

        let name = "SystemModulePackage"
        PackageBuilderTester(name, in: fs) { result in
            result.checkModule(name) { moduleResult in
                moduleResult.check(c99name: name, type: .systemModule)
                moduleResult.checkSources(root: "/")
            }
        }
    }

    func testResolvesSingleClangLibraryModule() throws {
        var fs = InMemoryFileSystem(emptyFiles:
            "/Foo.h",
            "/Foo.c")

        let name = "SingleClangModule"
        PackageBuilderTester(name, in: fs) { result in
            result.checkModule(name) { moduleResult in
                moduleResult.check(c99name: name, type: .library)
                moduleResult.checkSources(root: "/", paths: "Foo.c")
            }
        }

        // Single clang target inside Sources.
        fs = InMemoryFileSystem(emptyFiles:
            "/Sources/Foo.h",
            "/Sources/Foo.c")

        PackageBuilderTester(name, in: fs) { result in
            result.checkModule(name) { moduleResult in
                moduleResult.check(c99name: name, type: .library)
                moduleResult.checkSources(root: "/Sources", paths: "Foo.c")
            }
        }

        // Single clang target inside its own directory.
        fs = InMemoryFileSystem(emptyFiles:
            "/Sources/lib/Foo.h",
            "/Sources/lib/Foo.c")

        PackageBuilderTester(name, in: fs) { result in
            result.checkModule("lib") { moduleResult in
                moduleResult.check(c99name: "lib", type: .library)
                moduleResult.checkSources(root: "/Sources/lib", paths: "Foo.c")
            }
        }
    }

    func testSingleExecutableSwiftTarget() throws {
        // Single swift executable target.
        var fs = InMemoryFileSystem(emptyFiles:
            "/main.swift",
            "/Bar.swift")

        let name = "SingleExecutable"
        PackageBuilderTester(name, in: fs) { result in
            result.checkModule(name) { moduleResult in
                moduleResult.check(c99name: name, type: .executable)
                moduleResult.checkSources(root: "/", paths: "main.swift", "Bar.swift")
                moduleResult.check(swiftCompatibleVersions: nil)
            }
        }

        // Single swift executable target inside Sources.
        fs = InMemoryFileSystem(emptyFiles:
            "/Sources/main.swift")

        PackageBuilderTester(name, in: fs) { result in
            result.checkModule(name) { moduleResult in
                moduleResult.check(c99name: name, type: .executable)
                moduleResult.checkSources(root: "/Sources", paths: "main.swift")
            }
        }

        // Single swift executable target inside its own directory.
        fs = InMemoryFileSystem(emptyFiles:
            "/Sources/exec/main.swift")

        PackageBuilderTester(name, in: fs) { result in
            result.checkModule("exec") { moduleResult in
                moduleResult.check(c99name: "exec", type: .executable)
                moduleResult.checkSources(root: "/Sources/exec", paths: "main.swift")
            }
        }
    }

    func testCompatibleSwiftVersions() throws {
        // Single swift executable target.
        let fs = InMemoryFileSystem(emptyFiles:
            "/foo/main.swift",
            "/bar/bar.swift",
            "/Tests/fooTests/bar.swift"
            )

        let package = PackageDescription.Package(name: "pkg", swiftLanguageVersions: [3, 4])
        PackageBuilderTester(package, in: fs) { result in
            result.checkModule("foo") { moduleResult in
                moduleResult.check(c99name: "foo", type: .executable)
                moduleResult.checkSources(root: "/foo", paths: "main.swift")
                moduleResult.check(swiftCompatibleVersions: [3, 4])
            }

            result.checkModule("fooTests") { moduleResult in
                moduleResult.check(c99name: "fooTests", type: .test)
                moduleResult.checkSources(root: "/Tests/fooTests", paths: "bar.swift")
                moduleResult.check(swiftCompatibleVersions: [3, 4])
            }

            result.checkModule("bar") { moduleResult in
                moduleResult.check(c99name: "bar", type: .library)
                moduleResult.checkSources(root: "/bar", paths: "bar.swift")
                moduleResult.check(swiftCompatibleVersions: [3, 4])
            }
        }
    }

    func testSingleExecutableClangModule() throws {
        // Single swift executable target.
        var fs = InMemoryFileSystem(emptyFiles:
            "/main.c",
            "/Bar.c")

        let name = "SingleExecutable"
        PackageBuilderTester(name, in: fs) { result in
            result.checkModule(name) { moduleResult in
                moduleResult.check(c99name: name, type: .executable)
                moduleResult.checkSources(root: "/", paths: "main.c", "Bar.c")
            }
        }

        // Single swift executable target inside Sources.
        fs = InMemoryFileSystem(emptyFiles:
            "/Sources/main.cpp")

        PackageBuilderTester(name, in: fs) { result in
            result.checkModule(name) { moduleResult in
                moduleResult.check(c99name: name, type: .executable)
                moduleResult.checkSources(root: "/Sources", paths: "main.cpp")
            }
        }

        // Single swift executable target inside its own directory.
        fs = InMemoryFileSystem(emptyFiles:
            "/Sources/c/main.c")

        PackageBuilderTester(name, in: fs) { result in
            result.checkModule("c") { moduleResult in
                moduleResult.check(c99name: "c", type: .executable)
                moduleResult.checkSources(root: "/Sources/c", paths: "main.c")
            }
        }
    }

    func testDotSwiftSuffixDirectory() throws {
        var fs = InMemoryFileSystem(emptyFiles:
            "/hello.swift/dummy",
            "/main.swift",
            "/Bar.swift")

        let name = "pkg"
        // FIXME: This fails currently, it is a bug.
        #if false
        PackageBuilderTester(name, in: fs) { result in
            result.checkModule(name) { moduleResult in
                moduleResult.check(c99name: name, type: .executable)
                moduleResult.checkSources(root: "/", paths: "main.swift", "Bar.swift")
            }
        }
        #endif

        fs = InMemoryFileSystem(emptyFiles:
            "/hello.swift/dummy",
            "/Sources/main.swift",
            "/Sources/Bar.swift")

        PackageBuilderTester(name, in: fs) { result in
            result.checkModule(name) { moduleResult in
                moduleResult.check(c99name: name, type: .executable)
                moduleResult.checkSources(root: "/Sources", paths: "main.swift", "Bar.swift")
            }
        }

        fs = InMemoryFileSystem(emptyFiles:
            "/Sources/exe/hello.swift/dummy",
            "/Sources/exe/main.swift",
            "/Sources/exe/Bar.swift")

        PackageBuilderTester(name, in: fs) { result in
            result.checkModule("exe") { moduleResult in
                moduleResult.check(c99name: "exe", type: .executable)
                moduleResult.checkSources(root: "/Sources/exe", paths: "main.swift", "Bar.swift")
            }
        }
    }

    func testMultipleSwiftTargets() throws {
        let fs = InMemoryFileSystem(emptyFiles:
            "/Sources/A/main.swift",
            "/Sources/A/foo.swift",
            "/Sources/B/main.swift",
            "/Sources/C/Foo.swift")

        PackageBuilderTester("MultipleModules", in: fs) { result in
            result.checkModule("A") { moduleResult in
                moduleResult.check(c99name: "A", type: .executable)
                moduleResult.checkSources(root: "/Sources/A", paths: "main.swift", "foo.swift")
            }

            result.checkModule("B") { moduleResult in
                moduleResult.check(c99name: "B", type: .executable)
                moduleResult.checkSources(root: "/Sources/B", paths: "main.swift")
            }

            result.checkModule("C") { moduleResult in
                moduleResult.check(c99name: "C", type: .library)
                moduleResult.checkSources(root: "/Sources/C", paths: "Foo.swift")
            }
        }
    }

    func testMultipleClangModules() throws {
        let fs = InMemoryFileSystem(emptyFiles:
            "/Sources/A/main.c",
            "/Sources/A/foo.h",
            "/Sources/A/foo.c",
            "/Sources/B/include/foo.h",
            "/Sources/B/foo.c",
            "/Sources/B/bar.c",
            "/Sources/C/main.cpp")

        PackageBuilderTester("MultipleModules", in: fs) { result in
            result.checkModule("A") { moduleResult in
                moduleResult.check(c99name: "A", type: .executable)
                moduleResult.checkSources(root: "/Sources/A", paths: "main.c", "foo.c")
            }

            result.checkModule("B") { moduleResult in
                moduleResult.check(c99name: "B", type: .library)
                moduleResult.checkSources(root: "/Sources/B", paths: "foo.c", "bar.c")
            }

            result.checkModule("C") { moduleResult in
                moduleResult.check(c99name: "C", type: .executable)
                moduleResult.checkSources(root: "/Sources/C", paths: "main.cpp")
            }
        }
    }

    func testTestsLayoutsv3() throws {
        // We expect auto dependency between Foo and FooTests.
        //
        // Single target layout.
        for singleModuleSource in ["/", "/Sources/", "/Sources/Foo/"].lazy.map(AbsolutePath.init) {
            let fs = InMemoryFileSystem(emptyFiles:
                singleModuleSource.appending(component: "Foo.swift").asString,
                "/Tests/FooTests/FooTests.swift",
                "/Tests/FooTests/BarTests.swift",
                "/Tests/BarTests/BazTests.swift")

            PackageBuilderTester(.v3(.init(name: "Foo")), in: fs) { result in
                result.checkModule("Foo") { moduleResult in
                    moduleResult.check(c99name: "Foo", type: .library)
                    moduleResult.checkSources(root: singleModuleSource.asString, paths: "Foo.swift")
                }

                result.checkModule("FooTests") { moduleResult in
                    moduleResult.check(c99name: "FooTests", type: .test)
                    moduleResult.checkSources(root: "/Tests/FooTests", paths: "FooTests.swift", "BarTests.swift")
                    moduleResult.check(dependencies: ["Foo"])
                }

                result.checkModule("BarTests") { moduleResult in
                    moduleResult.check(c99name: "BarTests", type: .test)
                    moduleResult.checkSources(root: "/Tests/BarTests", paths: "BazTests.swift")
                    moduleResult.check(dependencies: [])
                }
            }
        }

        let fs = InMemoryFileSystem(emptyFiles:
            "/Sources/A/main.swift", // Swift exec
            "/Sources/B/Foo.swift",  // Swift lib
            "/Sources/D/Foo.c",      // Clang lib
            "/Sources/E/main.c",     // Clang exec
            "/Tests/ATests/Foo.swift",
            "/Tests/BTests/Foo.swift",
            "/Tests/DTests/Foo.swift",
            "/Tests/ETests/Foo.swift")

       PackageBuilderTester(.v3(.init(name: "Foo")), in: fs) { result in
           result.checkModule("A") { moduleResult in
               moduleResult.check(c99name: "A", type: .executable)
               moduleResult.checkSources(root: "/Sources/A", paths: "main.swift")
           }

           result.checkModule("B") { moduleResult in
               moduleResult.check(c99name: "B", type: .library)
               moduleResult.checkSources(root: "/Sources/B", paths: "Foo.swift")
           }

           result.checkModule("D") { moduleResult in
               moduleResult.check(c99name: "D", type: .library)
               moduleResult.checkSources(root: "/Sources/D", paths: "Foo.c")
           }

           result.checkModule("E") { moduleResult in
               moduleResult.check(c99name: "E", type: .executable)
               moduleResult.checkSources(root: "/Sources/E", paths: "main.c")
           }

           result.checkModule("ATests") { moduleResult in
               moduleResult.check(c99name: "ATests", type: .test)
               moduleResult.checkSources(root: "/Tests/ATests", paths: "Foo.swift")
               moduleResult.check(dependencies: ["A"])
           }

           result.checkModule("BTests") { moduleResult in
               moduleResult.check(c99name: "BTests", type: .test)
               moduleResult.checkSources(root: "/Tests/BTests", paths: "Foo.swift")
               moduleResult.check(dependencies: ["B"])
           }

           result.checkModule("DTests") { moduleResult in
               moduleResult.check(c99name: "DTests", type: .test)
               moduleResult.checkSources(root: "/Tests/DTests", paths: "Foo.swift")
               moduleResult.check(dependencies: ["D"])
           }

           result.checkModule("ETests") { moduleResult in
               moduleResult.check(c99name: "ETests", type: .test)
               moduleResult.checkSources(root: "/Tests/ETests", paths: "Foo.swift")
               moduleResult.check(dependencies: ["E"])
           }
       }
    }

    func testNoSources() throws {
        PackageBuilderTester("NoSources", in: InMemoryFileSystem()) { result in
            result.checkDiagnostic("The target NoSources in package NoSources does not contain any valid source files.")
        }
    }

    func testMixedSources() throws {
        let fs = InMemoryFileSystem(emptyFiles:
            "/Sources/main.swift",
            "/Sources/main.c")
        PackageBuilderTester("MixedSources", in: fs) { result in
            result.checkDiagnostic("the target at /Sources contains mixed language source files fix: use only a single language within a target")
        }
    }

    func testTwoModulesMixedLanguage() throws {
        let fs = InMemoryFileSystem(emptyFiles:
            "/Sources/ModuleA/main.swift",
            "/Sources/ModuleB/main.c",
            "/Sources/ModuleB/foo.c")

        PackageBuilderTester("MixedLanguage", in: fs) { result in
            result.checkModule("ModuleA") { moduleResult in
                moduleResult.check(c99name: "ModuleA", type: .executable)
                moduleResult.checkSources(root: "/Sources/ModuleA", paths: "main.swift")
            }

            result.checkModule("ModuleB") { moduleResult in
                moduleResult.check(c99name: "ModuleB", type: .executable)
                moduleResult.checkSources(root: "/Sources/ModuleB", paths: "main.c", "foo.c")
            }
        }
    }

    func testCInTests() throws {
        let fs = InMemoryFileSystem(emptyFiles:
            "/Sources/main.swift",
            "/Tests/MyPackageTests/abc.c")

        PackageBuilderTester("MyPackage", in: fs) { result in
            result.checkModule("MyPackage") { moduleResult in
                moduleResult.check(type: .executable)
                moduleResult.checkSources(root: "/Sources", paths: "main.swift")
            }

            result.checkModule("MyPackageTests") { moduleResult in
                moduleResult.check(type: .test)
                moduleResult.checkSources(root: "/Tests/MyPackageTests", paths: "abc.c")
            }

          #if os(Linux)
            result.checkDiagnostic("Ignoring target MyPackageTests in package MyPackage as C language in tests is not supported yet.")
          #endif
        }
    }

    func testValidSources() throws {
        let fs = InMemoryFileSystem(emptyFiles:
            "/main.swift",
            "/noExtension",
            "/Package.swift",
            "/.git/anchor",
            "/.xcodeproj/anchor",
            "/.playground/anchor",
            "/Package.swift",
            "/Packages/MyPackage/main.c")
        let name = "pkg"
        PackageBuilderTester(name, in: fs) { result in
            result.checkModule(name) { moduleResult in
                moduleResult.check(type: .executable)
                moduleResult.checkSources(root: "/", paths: "main.swift")
            }
        }
    }

    func testCustomTargetDependencies() throws {
        let fs = InMemoryFileSystem(emptyFiles:
            "/Sources/Foo/Foo.swift",
            "/Sources/Bar/Bar.swift",
            "/Sources/Baz/Baz.swift")

        // Direct.
        var package = PackageDescription.Package(name: "pkg", targets: [.init(name: "Foo", dependencies: ["Bar"])])
        PackageBuilderTester(package, in: fs) { result in
            result.checkModule("Foo") { moduleResult in
                moduleResult.check(c99name: "Foo", type: .library)
                moduleResult.checkSources(root: "/Sources/Foo", paths: "Foo.swift")
                moduleResult.check(dependencies: ["Bar"])
            }

            for target in ["Bar", "Baz"] {
                result.checkModule(target) { moduleResult in
                    moduleResult.check(c99name: target, type: .library)
                    moduleResult.checkSources(root: "/Sources/\(target)", paths: "\(target).swift")
                }
            }
        }

        // Transitive.
        package = PackageDescription.Package(
            name: "pkg",
            targets: [
                .init(name: "Foo", dependencies: ["Bar"]),
                .init(name: "Bar", dependencies: ["Baz"])
            ]
        )
        PackageBuilderTester(package, in: fs) { result in
            result.checkModule("Foo") { moduleResult in
                moduleResult.check(c99name: "Foo", type: .library)
                moduleResult.checkSources(root: "/Sources/Foo", paths: "Foo.swift")
                moduleResult.check(dependencies: ["Bar"])
            }

            result.checkModule("Bar") { moduleResult in
                moduleResult.check(c99name: "Bar", type: .library)
                moduleResult.checkSources(root: "/Sources/Bar", paths: "Bar.swift")
                moduleResult.check(dependencies: ["Baz"])
            }

            result.checkModule("Baz") { moduleResult in
                moduleResult.check(c99name: "Baz", type: .library)
                moduleResult.checkSources(root: "/Sources/Baz", paths: "Baz.swift")
            }
        }
    }

    func testTargetDependencies2() throws {
        let fs = InMemoryFileSystem(emptyFiles:
            "/Sources/Foo/Foo.swift",
            "/Sources/Bar/Bar.swift",
            "/Sources/Baz/Baz.swift")

        // We create a manifest which uses byName target dependencies.
        let package = PackageDescription.Package(
            name: "pkg",
            targets: [
                .init(
                    name: "Foo",
                    dependencies: ["Bar", "Baz", "Bam"]),
            ])

        PackageBuilderTester(package, in: fs) { result in
            result.checkDiagnostic("these referenced targets could not be found: Bam fix: reference only valid targets")
        }
    }

    func testTestTargetDependencies() throws {
        let fs = InMemoryFileSystem(emptyFiles:
            "/Sources/Foo/source.swift",
            "/Sources/Bar/source.swift",
            "/Tests/FooTests/source.swift"
        )

        let package = PackageDescription.Package(name: "pkg", targets: [.init(name: "FooTests", dependencies: ["Bar"])])
        PackageBuilderTester(package, in: fs) { result in
            result.checkModule("Foo") { moduleResult in
                moduleResult.check(c99name: "Foo", type: .library)
                moduleResult.checkSources(root: "/Sources/Foo", paths: "source.swift")
            }

            result.checkModule("Bar") { moduleResult in
                moduleResult.check(c99name: "Bar", type: .library)
                moduleResult.checkSources(root: "/Sources/Bar", paths: "source.swift")
            }

            result.checkModule("FooTests") { moduleResult in
                moduleResult.check(c99name: "FooTests", type: .test)
                moduleResult.checkSources(root: "/Tests/FooTests", paths: "source.swift")
                moduleResult.check(dependencies: ["Bar"])
            }
        }
    }

    func testInvalidTestTargets() throws {
        // Test target in Sources/
        var fs = InMemoryFileSystem(emptyFiles:
            "/Sources/FooTests/source.swift")
        PackageBuilderTester("TestsInSources", in: fs) { result in
            result.checkDiagnostic("the directory Sources/FooTests has an invalid name (\'FooTests\'): the name of a non-test target has a 'Tests' suffix fix: rename the directory 'Sources/FooTests' to not have a 'Tests' suffix")
        }

        // Normal target in Tests/
        fs = InMemoryFileSystem(emptyFiles:
            "/Sources/main.swift",
            "/Tests/Foo/source.swift")
        PackageBuilderTester("TestsInSources", in: fs) { result in
            result.checkDiagnostic("the directory Tests/Foo has an invalid name (\'Foo\'): the name of a test target has no 'Tests' suffix fix: rename the directory 'Tests/Foo' to have a 'Tests' suffix")
        }
    }

    func testLooseSourceFileInTestsDir() throws {
        // Loose source file in Tests/
        let fs = InMemoryFileSystem(emptyFiles:
            "/Sources/main.swift",
            "/Tests/source.swift")
        PackageBuilderTester("LooseSourceFileInTestsDir", in: fs) { result in
            result.checkDiagnostic("the package has an unsupported layout, unexpected source file(s) found: /Tests/source.swift fix: move the file(s) inside a target")
        }
    }
    
    func testManifestTargetDeclErrors() throws {
        // Reference a target which doesn't exist.
        var fs = InMemoryFileSystem(emptyFiles:
            "/Foo.swift")
        var package = PackageDescription.Package(name: "pkg", targets: [.init(name: "Random")])
        PackageBuilderTester(package, in: fs) { result in
            result.checkDiagnostic("these referenced targets could not be found: Random fix: reference only valid targets")
        }

        // Reference an invalid dependency.
        package = PackageDescription.Package(name: "pkg", targets: [.init(name: "pkg", dependencies: ["Foo"])])
        PackageBuilderTester(package, in: fs) { result in
            result.checkDiagnostic("these referenced targets could not be found: Foo fix: reference only valid targets")
        }

        // Reference self in dependencies.
        package = PackageDescription.Package(name: "pkg", targets: [.init(name: "pkg", dependencies: ["pkg"])])
        PackageBuilderTester(package, in: fs) { result in
            result.checkDiagnostic("found cyclic dependency declaration: pkg -> pkg")
        }

        fs = InMemoryFileSystem(emptyFiles:
            "/Sources/pkg1/Foo.swift",
            "/Sources/pkg2/Foo.swift",
            "/Sources/pkg3/Foo.swift"
        )
        // Cyclic dependency.
        package = PackageDescription.Package(name: "pkg", targets: [
            .init(name: "pkg1", dependencies: ["pkg2"]),
            .init(name: "pkg2", dependencies: ["pkg3"]),
            .init(name: "pkg3", dependencies: ["pkg1"]),
        ])
        PackageBuilderTester(package, in: fs) { result in
            result.checkDiagnostic("found cyclic dependency declaration: pkg1 -> pkg2 -> pkg3 -> pkg1")
        }

        package = PackageDescription.Package(name: "pkg", targets: [
            .init(name: "pkg1", dependencies: ["pkg2"]),
            .init(name: "pkg2", dependencies: ["pkg3"]),
            .init(name: "pkg3", dependencies: ["pkg2"]),
        ])
        PackageBuilderTester(package, in: fs) { result in
            result.checkDiagnostic("found cyclic dependency declaration: pkg1 -> pkg2 -> pkg3 -> pkg2")
        }

        // Executable as dependency.
        fs = InMemoryFileSystem(emptyFiles:
            "/Sources/exec/main.swift",
            "/Sources/lib/lib.swift")
        package = PackageDescription.Package(name: "pkg", targets: [.init(name: "lib", dependencies: ["exec"])])
        PackageBuilderTester(package, in: fs) { result in
            result.checkModule("exec") { moduleResult in
                moduleResult.check(c99name: "exec", type: .executable)
                moduleResult.checkSources(root: "/Sources/exec", paths: "main.swift")
            }

            result.checkModule("lib") { moduleResult in
                moduleResult.check(c99name: "lib", type: .library)
                moduleResult.checkSources(root: "/Sources/lib", paths: "lib.swift")
            }
        }

        // Reference a target which doesn't have sources.
        fs = InMemoryFileSystem(emptyFiles:
            "/Sources/pkg1/Foo.swift",
            "/Sources/pkg2/readme.txt")
        package = PackageDescription.Package(name: "pkg", targets: [.init(name: "pkg1", dependencies: ["pkg2"])])
        PackageBuilderTester(package, in: fs) { result in
            result.checkDiagnostic("The target pkg2 in package pkg does not contain any valid source files.")
            result.checkModule("pkg1") { moduleResult in
                moduleResult.check(c99name: "pkg1", type: .library)
                moduleResult.checkSources(root: "/Sources/pkg1", paths: "Foo.swift")
            }
        }
    }

    func testTestsProduct() throws {
        // Make sure product name and test target name are different in single target package.
        var fs = InMemoryFileSystem(emptyFiles:
            "/Sources/Foo.swift",
            "/Tests/FooTests/Bar.swift")

        PackageBuilderTester("Foo", in: fs) { result in
            result.checkModule("Foo") { moduleResult in
                moduleResult.check(c99name: "Foo", type: .library)
                moduleResult.checkSources(root: "/Sources", paths: "Foo.swift")
            }

            result.checkModule("FooTests") { moduleResult in
                moduleResult.check(c99name: "FooTests", type: .test)
                moduleResult.checkSources(root: "/Tests/FooTests", paths: "Bar.swift")
            }

            result.checkProduct("FooPackageTests") { productResult in
                productResult.check(type: .test, targets: ["FooTests"])
            }
        }

        // Multi target tests package.
        fs = InMemoryFileSystem(emptyFiles:
            "/Sources/Foo/Foo.swift",
            "/Sources/Bar/Bar.swift",
            "/Tests/FooTests/Foo.swift",
            "/Tests/BarTests/Bar.swift")

        PackageBuilderTester("Foo", in: fs) { result in
            result.checkModule("Foo") { moduleResult in
                moduleResult.check(c99name: "Foo", type: .library)
                moduleResult.checkSources(root: "/Sources/Foo", paths: "Foo.swift")
            }

            result.checkModule("Bar") { moduleResult in
                moduleResult.check(c99name: "Bar", type: .library)
                moduleResult.checkSources(root: "/Sources/Bar", paths: "Bar.swift")
            }

            result.checkModule("FooTests") { moduleResult in
                moduleResult.check(c99name: "FooTests", type: .test)
                moduleResult.checkSources(root: "/Tests/FooTests", paths: "Foo.swift")
            }

            result.checkModule("BarTests") { moduleResult in
                moduleResult.check(c99name: "BarTests", type: .test)
                moduleResult.checkSources(root: "/Tests/BarTests", paths: "Bar.swift")
            }

            result.checkProduct("FooPackageTests") { productResult in
                productResult.check(type: .test, targets: ["BarTests", "FooTests"])
            }
        }
    }

    func testVersionSpecificManifests() throws {
        let fs = InMemoryFileSystem(emptyFiles:
            "/Package.swift",
            "/Package@swift-999.swift",
            "/Sources/Package.swift",
            "/Sources/Package@swift-1.swift")

        let name = "Foo"
        PackageBuilderTester(name, in: fs) { result in
            result.checkModule(name) { moduleResult in
                moduleResult.check(c99name: name, type: .library)
                moduleResult.checkSources(root: "/Sources", paths: "Package.swift", "Package@swift-1.swift")
            }
        }
    }

    func testMultipleRoots() throws {
        var fs = InMemoryFileSystem(emptyFiles:
            "/Foo.swift",
            "/main.swift",
            "/src/FooBarLib/FooBar.swift")

        PackageBuilderTester("MyPackage", in: fs) { result in
            result.checkDiagnostic("the package has an unsupported layout, unexpected source file(s) found: /Foo.swift, /main.swift fix: move the file(s) inside a target")
        }

        fs = InMemoryFileSystem(emptyFiles:
            "/Sources/BarExec/main.swift",
            "/Sources/BarExec/Bar.swift",
            "/src/FooBarLib/FooBar.swift")

        PackageBuilderTester("MyPackage", in: fs) { result in
            result.checkDiagnostic("the package has an unsupported layout, multiple source roots found: /Sources, /src fix: remove the extra source roots, or add them to the source root exclude list")
        }
    }

    func testInvalidLayout1() throws {
        /*
         Package
         ├── main.swift   <-- invalid
         └── Sources
             └── File2.swift
        */
        let fs = InMemoryFileSystem(emptyFiles:
            "/Sources/Files2.swift",
            "/main.swift")

        PackageBuilderTester("MyPackage", in: fs) { result in
            result.checkDiagnostic("the package has an unsupported layout, unexpected source file(s) found: /main.swift fix: move the file(s) inside a target")
        }
    }

    func testInvalidLayout2() throws {
        /*
         Package
         ├── main.swift  <-- invalid
         └── Bar
             └── Sources
                 └── File2.swift
        */
        // FIXME: We should allow this by not making targets at root and only inside Sources/.
        let fs = InMemoryFileSystem(emptyFiles:
            "/Bar/Sources/Files2.swift",
            "/main.swift")

        PackageBuilderTester("MyPackage", in: fs) { result in
            result.checkDiagnostic("the package has an unsupported layout, unexpected source file(s) found: /main.swift fix: move the file(s) inside a target")
        }
    }

    func testInvalidLayout3() throws {
        /*
         Package
         └── Sources
             ├── main.swift  <-- Invalid
             └── Bar
                 └── File2.swift
        */
        let fs = InMemoryFileSystem(emptyFiles:
            "/Sources/main.swift",
            "/Sources/Bar/File2.swift")

        PackageBuilderTester("MyPackage", in: fs) { result in
            result.checkDiagnostic("the package has an unsupported layout, unexpected source file(s) found: /Sources/main.swift fix: move the file(s) inside a target")
        }
    }

    func testInvalidLayout4() throws {
        /*
         Package
         ├── main.swift  <-- Invalid
         └── Sources
             └── Bar
                 └── File2.swift
        */
        let fs = InMemoryFileSystem(emptyFiles:
            "/main.swift",
            "/Sources/Bar/File2.swift")

        PackageBuilderTester("MyPackage", in: fs) { result in
            result.checkDiagnostic("the package has an unsupported layout, unexpected source file(s) found: /main.swift fix: move the file(s) inside a target")
        }
    }

    func testInvalidLayout5() throws {
        /*
         Package
         ├── File1.swift
         └── Foo
             └── Foo.swift  <-- Invalid
        */
        // for the simplest layout it is invalid to have any
        // subdirectories. It is the compromise you make.
        // the reason for this is mostly performance in
        // determineTargets() but also we are saying: this
        // layout is only for *very* simple projects.
        let fs = InMemoryFileSystem(emptyFiles:
            "/File1.swift",
            "/Foo/Foo.swift")

        PackageBuilderTester("MyPackage", in: fs) { result in
            result.checkDiagnostic("the package has an unsupported layout, unexpected source file(s) found: /File1.swift fix: move the file(s) inside a target")
        }
    }

    func testInvalidLayout6() throws {
        let fs = InMemoryFileSystem(emptyFiles:
            "/Sources/file.swift",
            "/Sources/foo/foo.swift",
            "/Sources/bar/bar.swift")

        PackageBuilderTester("MyPackage", in: fs) { result in
            result.checkDiagnostic("the package has an unsupported layout, unexpected source file(s) found: /Sources/file.swift fix: move the file(s) inside a target")
        }
    }

    func testModuleMapLayout() throws {
       var fs = InMemoryFileSystem(emptyFiles:
            "/Sources/clib/include/module.modulemap",
            "/Sources/clib/include/clib.h",
            "/Sources/clib/clib.c")

        PackageBuilderTester("MyPackage", in: fs) { result in
            result.checkModule("clib") { moduleResult in
                moduleResult.check(c99name: "clib", type: .library)
                moduleResult.checkSources(root: "/Sources/clib", paths: "clib.c")
            }
        }

        fs = InMemoryFileSystem(emptyFiles:
            "/Sources/module.modulemap",
            "/Sources/foo.swift")

        PackageBuilderTester("MyPackage", in: fs) { result in
            result.checkDiagnostic("the package has an unsupported layout, modulemap (/Sources/module.modulemap) is not allowed to be mixed with sources fix: move the modulemap inside include directory")
        }

        fs = InMemoryFileSystem(emptyFiles:
            "/Sources/Foo/module.modulemap",
            "/Sources/Foo/foo.swift",
            "/Sources/Bar/bar.swift")

        PackageBuilderTester("MyPackage", in: fs) { result in
            result.checkDiagnostic("the package has an unsupported layout, modulemap (/Sources/Foo/module.modulemap) is not allowed to be mixed with sources fix: move the modulemap inside include directory")
        }
    }

    func testNoSourcesInModule() throws {
        var fs = InMemoryFileSystem()
        try fs.createDirectory(AbsolutePath("/Sources/Module"), recursive: true)
        PackageBuilderTester("MyPackage", in: fs) { result in
            result.checkDiagnostic("The target Module in package MyPackage does not contain any valid source files.")
        }

        fs = InMemoryFileSystem(emptyFiles:
            "/Sources/Module/foo.swift")
        try fs.createDirectory(AbsolutePath("/Tests/ModuleTests"), recursive: true)
        PackageBuilderTester("MyPackage", in: fs) { result in
            result.checkDiagnostic("The target ModuleTests in package MyPackage does not contain any valid source files.")
            result.checkModule("Module")
        }
    }

    func testExcludes() throws {
        let fs = InMemoryFileSystem(emptyFiles:
            "/Sources/A/main.swift",
            "/Sources/A/foo.swift", // File will be excluded.
            "/Sources/B/main.swift" // Dir will be excluded.
        )

        // Excluding everything.
        var package = PackageDescription.Package(name: "pkg", exclude: ["."])
        PackageBuilderTester(package, in: fs) { _ in }

        // Test excluding a file and a directory.
        package = PackageDescription.Package(name: "pkg", exclude: ["Sources/A/foo.swift", "Sources/B"])
        PackageBuilderTester(package, in: fs) { result in
            result.checkModule("A") { moduleResult in
                moduleResult.check(type: .executable)
                moduleResult.checkSources(root: "/Sources/A", paths: "main.swift")
            }
        }
    }

    func testInvalidManifestConfigForNonSystemModules() {
        var fs = InMemoryFileSystem(emptyFiles:
            "/Sources/main.swift"
        )
        var package = PackageDescription.Package(name: "pkg", pkgConfig: "foo")

        PackageBuilderTester(package, in: fs) { result in
            result.checkDiagnostic("invalid configuration in 'pkg': pkgConfig should only be used with a System Module Package")
        }

        fs = InMemoryFileSystem(emptyFiles:
            "/Sources/Foo/main.c"
        )
        package = PackageDescription.Package(name: "pkg", providers: [.Brew("foo")])

        PackageBuilderTester(package, in: fs) { result in
            result.checkDiagnostic("invalid configuration in 'pkg': providers should only be used with a System Module Package")
        }
    }

    static var allTests = [
        ("testCInTests", testCInTests),
        ("testCompatibleSwiftVersions", testCompatibleSwiftVersions),
        ("testCustomTargetDependencies", testCustomTargetDependencies),
        ("testDotFilesAreIgnored", testDotFilesAreIgnored),
        ("testDotSwiftSuffixDirectory", testDotSwiftSuffixDirectory),
        ("testExcludes", testExcludes),
        ("testInvalidLayout1", testInvalidLayout1),
        ("testInvalidLayout2", testInvalidLayout2),
        ("testInvalidLayout3", testInvalidLayout3),
        ("testInvalidLayout4", testInvalidLayout4),
        ("testInvalidLayout5", testInvalidLayout5),
        ("testInvalidLayout6", testInvalidLayout5),
        ("testInvalidManifestConfigForNonSystemModules", testInvalidManifestConfigForNonSystemModules),
        ("testInvalidTestTargets", testInvalidTestTargets),
        ("testLooseSourceFileInTestsDir", testLooseSourceFileInTestsDir),
        ("testManifestTargetDeclErrors", testManifestTargetDeclErrors),
        ("testMixedSources", testMixedSources),
        ("testModuleMapLayout", testModuleMapLayout),
        ("testMultipleClangModules", testMultipleClangModules),
        ("testMultipleRoots", testMultipleRoots),
        ("testMultipleSwiftTargets", testMultipleSwiftTargets),
        ("testNoSources", testNoSources),
        ("testNoSourcesInModule", testNoSourcesInModule),
        ("testResolvesSingleClangLibraryModule", testResolvesSingleClangLibraryModule),
        ("testResolvesSingleSwiftLibraryModule", testResolvesSingleSwiftLibraryModule),
        ("testResolvesSystemModulePackage", testResolvesSystemModulePackage),
        ("testSingleExecutableClangModule", testSingleExecutableClangModule),
        ("testSingleExecutableSwiftTarget", testSingleExecutableSwiftTarget),
        ("testTargetDependencies2", testTargetDependencies2),
        ("testTestTargetDependencies", testTestTargetDependencies),
        ("testTestsLayoutsv3", testTestsLayoutsv3),
        ("testTestsProduct", testTestsProduct),
        ("testTwoModulesMixedLanguage", testTwoModulesMixedLanguage),
        ("testValidSources", testValidSources),
        ("testVersionSpecificManifests", testVersionSpecificManifests),
    ]
}

final class PackageBuilderTester {
    private enum Result {
        case package(PackageModel.Package)
        case error(String)
    }

    /// Contains the result produced by PackageBuilder.
    private let result: Result

    /// Contains the diagnostics which have not been checked yet.
    private var uncheckedDiagnostics = Set<String>()

    /// Contains the targets which have not been checked yet.
    private var uncheckedModules = Set<PackageModel.Target>()

    @discardableResult
    convenience init(
        _ package: PackageDescription4.Package,
        path: AbsolutePath = .root,
        in fs: FileSystem,
        file: StaticString = #file,
        line: UInt = #line,
        _ body: (PackageBuilderTester) -> Void
    ) {
       self.init(.v4(package), path: path, in: fs, file: file, line: line, body)
    }

    @discardableResult
    convenience init(
        _ package: PackageDescription.Package,
        path: AbsolutePath = .root,
        in fs: FileSystem,
        file: StaticString = #file,
        line: UInt = #line,
        _ body: (PackageBuilderTester) -> Void
    ) {
       self.init(.v3(package), path: path, in: fs, file: file, line: line, body)
    }

    @discardableResult
    convenience init(
        _ name: String,
        path: AbsolutePath = .root,
        in fs: FileSystem,
        file: StaticString = #file,
        line: UInt = #line,
        _ body: (PackageBuilderTester) -> Void
    ) {
       self.init(PackageDescription.Package(name: name), path: path, in: fs, file: file, line: line, body)
    }

    @discardableResult
    init(
        _ package: Manifest.RawPackage,
        path: AbsolutePath = .root,
        shouldCreateMultipleTestProducts: Bool = false,
        in fs: FileSystem,
        file: StaticString = #file,
        line: UInt = #line,
        _ body: (PackageBuilderTester) -> Void
    ) {
        let diagnostics = DiagnosticsEngine()
        do {
            let manifest = Manifest(path: path.appending(component: Manifest.filename), url: "", package: package, version: nil)
            // FIXME: We should allow customizing root package boolean.
            let builder = PackageBuilder(
                manifest: manifest, path: path, fileSystem: fs, diagnostics: diagnostics,
                isRootPackage: true, shouldCreateMultipleTestProducts: shouldCreateMultipleTestProducts)
            let loadedPackage = try builder.construct()
            result = .package(loadedPackage)
            uncheckedModules = Set(loadedPackage.targets)
        } catch {
            let errorStr = String(describing: error)
            result = .error(errorStr)
            uncheckedDiagnostics.insert(errorStr)
        }
        uncheckedDiagnostics.formUnion(diagnostics.diagnostics.map({ $0.localizedDescription }))
        body(self)
        validateDiagnostics(file: file, line: line)
        validateCheckedModules(file: file, line: line)
    }

    private func validateDiagnostics(file: StaticString, line: UInt) {
        guard !uncheckedDiagnostics.isEmpty else { return }
        XCTFail("Unchecked diagnostics: \(uncheckedDiagnostics)", file: file, line: line)
    }

    private func validateCheckedModules(file: StaticString, line: UInt) {
        guard !uncheckedModules.isEmpty else { return }
        XCTFail("Unchecked targets: \(uncheckedModules)", file: file, line: line)
    }

    func checkDiagnostic(_ str: String, file: StaticString = #file, line: UInt = #line) {
        if uncheckedDiagnostics.contains(str) {
            uncheckedDiagnostics.remove(str)
        } else {
            XCTFail("\(result) did not have error: \(str) or is already checked", file: file, line: line)
        }
    }

    func checkModule(_ name: String, file: StaticString = #file, line: UInt = #line, _ body: ((ModuleResult) -> Void)? = nil) {
        guard case .package(let package) = result else {
            return XCTFail("Expected package did not load \(self)", file: file, line: line)
        }
        guard let target = package.targets.first(where: {$0.name == name}) else {
            return XCTFail("Module: \(name) not found", file: file, line: line)
        }
        uncheckedModules.remove(target)
        body?(ModuleResult(target))
    }

    func checkProduct(_ name: String, file: StaticString = #file, line: UInt = #line, _ body: ((ProductResult) -> Void)? = nil) {
        guard case .package(let package) = result else {
            return XCTFail("Expected package did not load \(self)", file: file, line: line)
        }
        let foundProducts = package.products.filter{$0.name == name}
        guard foundProducts.count == 1 else {
            return XCTFail("Couldn't get the product: \(name). Found products \(foundProducts)", file: file, line: line)
        }
        body?(ProductResult(foundProducts[0]))
    }

    final class ProductResult {
        private let product: PackageModel.Product

        init(_ product: PackageModel.Product) {
            self.product = product
        }

        func check(type: PackageModel.ProductType, targets: [String], file: StaticString = #file, line: UInt = #line) {
            XCTAssertEqual(product.type, type, file: file, line: line)
            XCTAssertEqual(product.targets.map{$0.name}.sorted(), targets.sorted(), file: file, line: line)
        }
    }

    final class ModuleResult {
        private let target: PackageModel.Target

        fileprivate init(_ target: PackageModel.Target) {
            self.target = target
        }

        func check(c99name: String? = nil, type: PackageModel.Target.Kind? = nil, file: StaticString = #file, line: UInt = #line) {
            if let c99name = c99name {
                XCTAssertEqual(target.c99name, c99name, file: file, line: line)
            }
            if let type = type {
                XCTAssertEqual(target.type, type, file: file, line: line)
            }
        }

        func checkSources(root: String? = nil, sources paths: [String], file: StaticString = #file, line: UInt = #line) {
            if let root = root {
                XCTAssertEqual(target.sources.root, AbsolutePath(root), file: file, line: line)
            }
            let sources = Set(self.target.sources.relativePaths.map{$0.asString})
            XCTAssertEqual(sources, Set(paths), "unexpected source files in \(target.name)", file: file, line: line)
        }

        func checkSources(root: String? = nil, paths: String..., file: StaticString = #file, line: UInt = #line) {
            checkSources(root: root, sources: paths, file: file, line: line)
        }

        func check(dependencies depsToCheck: [String], file: StaticString = #file, line: UInt = #line) {
            XCTAssertEqual(Set(depsToCheck), Set(target.dependencies.map{$0.name}), "unexpected dependencies in \(target.name)", file: file, line: line)
        }

        func check(productDeps depsToCheck: [(name: String, package: String?)], file: StaticString = #file, line: UInt = #line) {
            guard depsToCheck.count == target.productDependencies.count else {
                return XCTFail("Incorrect product dependencies", file: file, line: line)
            }
            for (idx, element) in depsToCheck.enumerated() {
                let rhs = target.productDependencies[idx]
                guard element.name == rhs.name && element.package == rhs.package else {
                    return XCTFail("Incorrect product dependencies", file: file, line: line)
                }
            }
        }

        func check(swiftCompatibleVersions versions: [Int]? = nil, file: StaticString = #file, line: UInt = #line) {
            guard case let swiftTarget as SwiftTarget = target else {
                return XCTFail("\(target) is not a swift target", file: file, line: line)
            }
            switch (swiftTarget.swiftLanguageVersions, versions) {
            case (nil, nil):
                break
            case (let lhs?, let rhs?):
                XCTAssertEqual(lhs, rhs, file: file, line: line)
            default:
                XCTFail("\(swiftTarget.swiftLanguageVersions.debugDescription) is not equal to \(versions.debugDescription)", file: file, line: line)
            }
        }
    }
}
