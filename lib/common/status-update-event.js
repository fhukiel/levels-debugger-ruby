'use babel';

export default class StatusUpdateEvent {
  constructor(status, displayMessage, isBlocking, styleClass) {
    this.status = status;
    this.displayMessage = displayMessage;
    this.isBlocking = isBlocking;
    this.styleClass = styleClass;
  }

  getStatus() {
    return this.status;
  }

  getDisplayMessage() {
    return this.displayMessage;
  }

  isBlockingStatus() {
    return this.isBlocking;
  }

  getStyleClass() {
    return this.styleClass;
  }
}