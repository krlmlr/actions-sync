json <- '{"include":[{"os": "macos-latest", "r": "release"}, {"os": "ubuntu-20.04", "r": "release"}, {"os": "ubuntu-22.04", "r": "devel", "http-user-agent": "release"}]}'
if (Sys.getenv("GITHUB_OUTPUT") != "") {
  writeLines(paste0("matrix=", json), Sys.getenv("GITHUB_OUTPUT"))
}
writeLines(json)
