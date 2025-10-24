String removePaddingFromBase64(String base64Input) {
  var endIndex = base64Input.length;

  while (endIndex > 0 && base64Input[endIndex - 1] == '=') {
    endIndex--;
  }

  return base64Input.substring(0, endIndex);
}
