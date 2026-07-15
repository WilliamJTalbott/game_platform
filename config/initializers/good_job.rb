Rails.application.config.good_job.enable_cron = true

Rails.application.config.good_job.cron = {
  clean_up: {
    cron: "*/15 * * * *",
    class: "CleanGamesJob",
  }
}