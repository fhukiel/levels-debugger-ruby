'use babel';

export default class Position {
  constructor(line, column) {
    this.line = line;
    this.column = column;
  }

  getLine() {
    return this.line;
  }

  getColumn() {
    return this.column;
  }

  isOnSameLine(other) {
    if (other) {
      return other.getLine() === this.line;
    }

    return false;
  }
}