  package kafkatopic_naming

# Default to allow, unless a deny rule matches
default allow = true

# Deny if any topic name is invalid
deny[msg] {
    # Handle both single object and array of objects (multi-document YAML)
    topics := is_array(input) ? input : [input]
    some i
    topic := topics[i]

    topic.kind == "KafkaTopic"
    name := topic.metadata.name
    not valid_topic_name(name)
    msg := sprintf("KafkaTopic name '%s' is invalid. It must match the pattern '^demo-topic-[0-9]+$'.", [name])
}

# Helper function to validate the name
valid_topic_name(name) {
    re_match("^demo-topic-[0-9]+$", name)
}

re_match("^demo-topic-[0-9]+$", name)
}
