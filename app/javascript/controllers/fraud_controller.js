import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  injectToken(event) {
    castle.injectTokenOnSubmit(event);
  }
}
