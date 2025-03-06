// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import { Application } from "@hotwired/stimulus"
import ChartController from "./controllers/chart_controller"

const application = Application.start()
application.register("chart", ChartController)
