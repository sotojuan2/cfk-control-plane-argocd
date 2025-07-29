package kafkatopic.naming

# Support for both single object and array of objects (as in multi-document YAML)
deny[msg] {
  some i
  topic := input[i]
  topic.kind == "KafkaTopic"
  name := topic.metadata.name
  not valid_name(name)
  msg := sprintf("Kafka topic name '%v' does not follow the required naming pattern", [name])
}

deny[msg] {
  input.kind == "KafkaTopic"
  name := input.metadata.name
  not valid_name(name)
  msg := sprintf("Kafka topic name '%v' does not follow the required naming pattern", [name])
}

valid_name(name) {
  re_match("^demo-topic-[0-9]+$", name)
}
