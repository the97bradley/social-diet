import assert from "node:assert/strict";
import { test } from "node:test";
import { validateSignup } from "./_lib.mjs";

test("rejects short password or missing at", () => {
  assert.equal(
    validateSignup({ email: "not-an-email", password: "secret1", username: "brad" }),
    "Enter a valid email and a password of at least 6 characters.",
  );
  assert.equal(
    validateSignup({ email: "a@b.co", password: "123", username: "brad" }),
    "Enter a valid email and a password of at least 6 characters.",
  );
});

test("rejects bad usernames", () => {
  assert.equal(
    validateSignup({ email: "a@b.co", password: "secret1", username: "ab" }),
    "Username must be 3-24 letters, numbers, or underscores.",
  );
  assert.equal(
    validateSignup({ email: "a@b.co", password: "secret1", username: "Bad Name" }),
    "Username must be 3-24 letters, numbers, or underscores.",
  );
});

test("accepts a normal signup payload", () => {
  assert.equal(
    validateSignup({ email: "a@b.co", password: "secret1", username: "brad_1" }),
    null,
  );
});
