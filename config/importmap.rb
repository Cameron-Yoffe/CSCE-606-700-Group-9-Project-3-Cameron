# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/lib", under: "lib"
pin "gsap", to: "https://ga.jspm.io/npm:gsap@3.12.5/index.js"
pin "gsap/ScrollTrigger", to: "https://ga.jspm.io/npm:gsap@3.12.5/ScrollTrigger.js"
pin "chart.js", to: "https://cdn.jsdelivr.net/npm/chart.js@4.4.1/+esm"
