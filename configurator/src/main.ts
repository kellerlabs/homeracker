import "./style.css";
import "./configurator.css";
import { mountConfigurator } from "./app";
import { qs } from "./ui/dom";

mountConfigurator(qs<HTMLElement>(document, "#app"), { partsUrl: `${import.meta.env.BASE_URL}parts/` });
