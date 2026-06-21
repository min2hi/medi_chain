allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val configureAndroid = {
        if (extensions.findByName("android") != null) {
            configure<com.android.build.gradle.BaseExtension> {
                if (namespace == null) {
                    namespace = "com.medi_chain.${project.name.replace("-", "_").replace(".", "_")}"
                }

                if (project.name != "app") {
                    compileOptions {
                        sourceCompatibility = JavaVersion.VERSION_17
                        targetCompatibility = JavaVersion.VERSION_17
                    }
                }
            }

            tasks.matching { it.name.contains("Kotlin") }.configureEach {
                try {
                    val getKotlinOptions = this.javaClass.getMethod("getKotlinOptions")
                    val kotlinOptions = getKotlinOptions.invoke(this)
                    val setJvmTarget = kotlinOptions.javaClass.getMethod("setJvmTarget", String::class.java)
                    setJvmTarget.invoke(kotlinOptions, "17")
                } catch (e: Exception) {
                    // Ignore if the task does not have kotlinOptions
                }
            }

            val removePackageAttrTask = tasks.register("removePackageAttrFromXml") {
                doLast {
                    val manifestFile = file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val content = manifestFile.readText()
                        val updatedContent = content.replace(Regex("""package="[^"]*""""), "")
                        if (content != updatedContent) {
                            manifestFile.writeText(updatedContent)
                            logger.quiet("Removed package attribute from manifest of subproject ${project.name}")
                        }
                    }
                }
            }

            tasks.matching { it.name.contains("Manifest", ignoreCase = true) && it.name != "removePackageAttrFromXml" }.configureEach {
                dependsOn(removePackageAttrTask)
            }
        }
    }

    if (state.executed) {
        configureAndroid()
    } else {
        afterEvaluate {
            configureAndroid()
        }
    }
}
