package kafkatopic_naming

# Allow only if there are no deny messages
allow if {
    count(deny) == 0
}

# Deny if a single topic object has an invalid name
deny contains msg if {
    input.kind == "KafkaTopic"
    name := input.metadata.name
    not valid_topic_name(name)
    msg := sprintf("KafkaTopic name '%s' is invalid. It must match the pattern '^demo-topic-[0-9]+$'.", [name])
}

# Deny if any topic in an array of topics has an invalid name
deny contains msg if {
    some i
    topic := input[i]
    topic.kind == "KafkaTopic"
    name := topic.metadata.name
    not valid_topic_name(name)
    msg := sprintf("KafkaTopic name '%s' is invalid. It must match the pattern '^demo-topic-[0-9]+$'.", [name])
}

# Helper function to validate the name
valid_topic_name(name) if {
    regex.match("^demo-topic-[0-9]+$", name)
}
