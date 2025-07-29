package kafkatopic_naming

# Default to allow, unless a deny rule matches
default allow = true

# Deny if a single topic object has an invalid name
deny[msg] {
    input.kind == "KafkaTopic"
    name := input.metadata.name
    not valid_topic_name(name)
    msg := sprintf("KafkaTopic name '%s' is invalid. It must match the pattern '^demo-topic-[0-9]+$'.", [name])
}

# Deny if any topic in an array of topics has an invalid name
deny[msg] {
    some i
    topic := input[i]
    topic.kind == "KafkaTopic"
    name := topic.metadata.name
    not valid_topic_name(name)
    msg := sprintf("KafkaTopic name '%s' is invalid. It must match the pattern '^demo-topic-[0-9]+$'.", [name])
}

# Helper function to validate the name
valid_topic_name(name) {
    re_match("^demo-topic-[0-9]+$", name)
}


