package rules_intellij.indexing

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.node.ArrayNode
import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.project.Project
import java.nio.file.Path
import kotlin.io.path.div
import kotlin.io.path.notExists
import kotlin.io.path.pathString

class PredefinedJsonSharedIndexLocalFinder: SharedIndexLocalFinder {
  private companion object {
    //val log = logger<PredefinedJsonSharedIndexLocalFinder>()

    val projectRelativeIndexJsonLocation: String? = System.getProperty("local.project.shared.index.json.path")
  }

  override fun findSharedIndexChunks(project: Project): List<Path> {
    val basePath = project.basePath ?: return emptyList()
    val relativeJsonLocation = projectRelativeIndexJsonLocation ?: return emptyList()
    val jsonFileLocation = Path.of(basePath) / relativeJsonLocation
    if (jsonFileLocation.notExists()) return emptyList()
    try {
      val node = ObjectMapper().readTree(jsonFileLocation.toFile())
      val sharedIndexList = node.get("shared-indexes") as ArrayNode
      return sharedIndexList.map { Path.of(it.asText()) }
    }
    catch (e: Exception) {
      //log.warn("Can't read ${jsonFileLocation.pathString}", e)
    }
    return emptyList()
  }
}