'use babel';

export default class VariableTableEntry {
  constructor(name, value, address) {
    this.name = name;
    this.value = value;
    this.address = address;
    this.changed = false;
    this.changedExpiresAt = 0;
  }

  getName() {
    return this.name;
  }

  getValue() {
    return this.value;
  }

  getAddress() {
    return this.address;
  }

  isChanged() {
    return this.changed && !this.isChangedExpired();
  }

  setChanged(changed) {
    this.changed = changed;
    if (this.changed) {
      this.changedExpiresAt = Date.now() + 20;
    }
  }

  getChangedExpiresAt() {
    return this.changedExpiresAt;
  }

  isChangedExpired() {
    return this.changedExpiresAt < Date.now();
  }

  setChangedExpiresAt(changedExpiresAt) {
    this.changedExpiresAt = changedExpiresAt;
  }

  equals(other) {
    if (!other) {
      return false;
    }
    if (other.getName() !== this.name) {
      return false;
    }
    if (other.getValue() !== this.value) {
      return false;
    }
    if (other.getAddress() !== this.address) {
      return false;
    }

    return true;
  }
}