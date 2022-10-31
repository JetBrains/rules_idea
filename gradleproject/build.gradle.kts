import com.google.protobuf.gradle.*
import org.jetbrains.intellij.tasks.RunIdeTask
import org.gradle.internal.os.OperatingSystem
import kotlin.collections.setOf

plugins {
    id("java")
    id("org.jetbrains.kotlin.jvm") version "1.7.10"
    id("org.jetbrains.intellij") version "1.8.1"
    id("com.google.protobuf") version "0.8.19"
}

group = "com.example"
version = "1.0-SNAPSHOT"
val grpcVersion = "1.48.1"
val grpcKotlinVersion = "1.3.0"
val protobufVersion = "3.15.8"
val coroutinesVersion = "1.6.4"
val nettyVersion = "4.1.79.Final"

repositories {
    mavenCentral()
}

dependencies {
    implementation("javax.annotation:javax.annotation-api:1.3.2")
    implementation("io.grpc:grpc-protobuf:$grpcVersion")
    implementation("io.grpc:grpc-stub:$grpcVersion")
    implementation("io.grpc:grpc-netty:$grpcVersion")
    implementation("io.grpc:grpc-kotlin-stub:$grpcKotlinVersion")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:$coroutinesVersion")
    runtimeOnly("io.grpc:grpc-netty:$grpcVersion")

    implementation("io.netty:netty-transport-native-epoll:$nettyVersion")
    implementation("io.netty:netty-transport-native-kqueue:$nettyVersion")

    val arch = System.getProperty("os.arch")
    val is86_64 = setOf("x86_64", "amd64", "x64", "x86-64").contains(arch)
    val isArm64 = arch == "arm64"
    if (OperatingSystem.current().isLinux) {
        if (is86_64) {
            implementation("io.netty:netty-transport-native-epoll:$nettyVersion:linux-x86_64")
        } else if (isArm64) {
            implementation("io.netty:netty-transport-native-epoll:$nettyVersion:linux-aarch_64")
        }
    } else if (OperatingSystem.current().isMacOsX) {
        if (is86_64) {
            implementation("io.netty:netty-transport-native-kqueue:$nettyVersion:osx-x86_64")
        } else if (isArm64) {
            implementation("io.netty:netty-transport-native-kqueue:$nettyVersion:osx-aarch_64")
        }
    }
}

protobuf {
    protoc {
        artifact = "com.google.protobuf:protoc:$protobufVersion"
    }
    plugins {
        id("grpc") {
            artifact = "io.grpc:protoc-gen-grpc-java:$grpcVersion"
        }
        id("grpckt") {
            artifact = "io.grpc:protoc-gen-grpc-kotlin:$grpcKotlinVersion:jdk8@jar"
        }
    }
    generateProtoTasks {
        ofSourceSet("main").forEach {
            it.plugins {
                id("grpc")
                id("grpckt")
            }
        }
    }
}

sourceSets {
    main {
        proto {
            srcDir("$projectDir/../src/main/proto")
        }
        java {
            srcDir("$projectDir/../src/main/kotlin/rules_intellij/indexing")
            srcDir("$projectDir/../src/main/kotlin/rules_intellij/domain_socket")
        }
        resources {
            srcDir("$projectDir/../src/main/resources")
        }
    }
}


// Configure Gradle IntelliJ Plugin - read more: https://github.com/JetBrains/gradle-intellij-plugin
intellij {
    version.set("2022.2.3")
    type.set("IU") // Target IDE Platform
    plugins.set(listOf(
        "intellij.indexing.shared:222.4345.14",
        "intellij.indexing.shared.core"
    ))
}

tasks {
    // Set the JVM compatibility versions
    withType<JavaCompile> {
        sourceCompatibility = "11"
        targetCompatibility = "11"
    }

    withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
        kotlinOptions.jvmTarget = "11"
    }

    patchPluginXml {
        sinceBuild.set("212")
        untilBuild.set("222.*")
    }

    signPlugin {
        certificateChain.set(System.getenv("CERTIFICATE_CHAIN"))
        privateKey.set(System.getenv("PRIVATE_KEY"))
        password.set(System.getenv("PRIVATE_KEY_PASSWORD"))
    }

    publishPlugin {
        token.set(System.getenv("PUBLISH_TOKEN"))
    }
}
