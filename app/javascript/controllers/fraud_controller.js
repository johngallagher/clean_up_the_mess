import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  injectToken(event) {
    console.log("injectToken");
    castle.injectTokenOnSubmit(event);
  }
}
