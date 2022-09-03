package app.demo.todo.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import app.demo.todo.AppConfig;
import app.demo.todo.utils.AppLogger;

@Controller
public class InfoWebController {

	public static final AppLogger LOGGER = new AppLogger(InfoWebController.class);

	@GetMapping("/info")
	public String getIndex(Model model) {
		LOGGER.debug("TODO GET called with action '/info'");

		model.addAttribute("version", new AppConfig().getVersion());
		model.addAttribute("environment", new AppConfig().getEnvironment());

		return "info";
	}
}