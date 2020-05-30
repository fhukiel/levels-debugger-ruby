'use babel';

export default class Breakpoint {
  constructor(position, marker) {
    this.position = position;
    this.marker = marker;
  }

  getPosition() {
    return this.position;
  }

  destroyMarker() {
    if (this.marker) {
      this.marker.destroy();
    }
    this.marker = null;
  }

  hasMarker() {
    return !!this.marker;
  }

  setMarker(marker) {
    this.marker = marker;
  }
}