import "./cable_stream_source_element"

import * as Turbo from "@hotwired/turbo"
export { Turbo }

import * as cable from "./cable"
export { cable }

import { encodeMethodIntoRequestBody } from "./fetch_requests"

window.Turbo = Turbo

addEventListener("turbo:before-fetch-request", encodeMethodIntoRequestBody)
