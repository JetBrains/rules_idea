package rules_intellij.indexing

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.node.ArrayNode
import com.intellij.openapi.project.Project
import java.nio.file.Path
import kotlin.io.path.div

class PredefinedJsonSharedIndexLocalFinder: SharedIndexLocalFinder {
  private companion object {
    const val jsonPathId = "local.project.shared.index.json.path"
    val projectIndexJsonLocation: String? = System.getProperty(jsonPathId) ?: System.getenv(jsonPathId)
    const val workspacePathEnv = "BUILD_WORKSPACE_DIRECTORY"
    val workspacePath: String? = System.getenv(workspacePathEnv)
  }

  private fun unwrapPath(path: Path, base: Path): Path {
    if (path.isAbsolute) return path
    return base / path
  }

  override fun findSharedIndexChunks(project: Project): List<Path> {
    val basePath = Path.of(workspacePath ?: project.basePath ?: return emptyList())
    val jsonLocation = Path.of(projectIndexJsonLocation ?: return emptyList())
    val node = ObjectMapper().readTree(unwrapPath(jsonLocation, basePath).toFile())
    val sharedIndexList = node.get("shared-indexes") as ArrayNode
    return sharedIndexList.map { unwrapPath(Path.of(it.asText()), basePath) }
  }
}