// ignore_for_file: avoid_print

void main() {
  print('FAIL');
  // use fake firestore and config
  // test rate limiting by spamming multiple calls
  // test conflict by pre-creating meta document
  // test atomicity by causing an error in the middle of the transaction
  // test successful creation and verify data in fake firestore (and print it out):
  //  - verify annual metadata document
  //  - verify all monthly goals
  //  - verify log document
}
