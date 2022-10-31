load("@rules_intellij//intellij:plugin.bzl", "wrap_plugin")

def inject_indexing(name, ide_repo):
    wrap_plugin(
        name = "indexing",
        srcs = [ "@rules_intellij//src/main/kotlin/rules_intellij/indexing:srcs" ],
        ide_repo = ide_repo,
        ide_plugins = [
            "indexing-shared-ultimate",
            "indexing-shared",
        ],
        deps = [
            "@rules_intellij//src/main/proto:indexing_mediator_java_proto",
            "@rules_intellij//src/main/proto:indexing_mediator_java_grpc_proto",

            "@rules_intellij//src/main/proto:indexing_mediator_kt_proto",
            "@rules_intellij//src/main/proto:indexing_mediator_kt_grpc_proto",

            "@rules_intellij//src/main/java/rules_intellij/domain_socket",

            "@com_google_protobuf//:protobuf_java",
            "@com_google_protobuf//:protobuf_java_util",

            "@io_grpc_grpc_java//api",
            "@io_grpc_grpc_java//netty",
            "@io_grpc_grpc_java//protobuf",
            "@io_grpc_grpc_java//stub",

            "@rules_intellij_maven//:com_google_api_grpc_proto_google_common_protos",
            "@rules_intellij_maven//:com_google_code_findbugs_jsr305",
            "@rules_intellij_maven//:com_google_code_gson_gson",
            "@rules_intellij_maven//:com_google_guava_guava",

            "@io_netty_netty_transport_native_epoll//jar",
            "@io_netty_netty_transport_native_kqueue//jar",
        ],
        resources = [
            "@rules_intellij//src/main/resources/META-INF:plugin.xml",
            "@rules_intellij//src/main/resources/META-INF:pluginIcon.svg",
        ],
    )
