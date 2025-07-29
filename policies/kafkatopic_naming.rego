package kafkatopic_naming

# Default decision - allow only if there are no deny messages
default allow = false

allow {
    count(deny) == 0
}

# Deny if the input is not a valid format (neither a single object nor an array)
deny[msg] {
    not is_object(input)
    not is_array(input)
    msg := "Invalid input format: must be a valid KafkaTopic object or array of objects"
}

# Deny if a single topic object is missing metadata
deny[msg] {
    input.kind == "KafkaTopic"
    not input.metadata
    msg := sprintf("KafkaTopic is missing required 'metadata' field", [])
}

# Deny if a single topic object is missing the name field
deny[msg] {
    input.kind == "KafkaTopic"
    input.metadata
    not input.metadata.name
    msg := sprintf("KafkaTopic metadata is missing required 'name' field", [])
}

# Deny if a single topic object has an invalid name
deny[msg] {
    input.kind == "KafkaTopic"
    input.metadata.name
    name := input.metadata.name
    not valid_topic_name(name)
    reason := get_validation_error(name)
    msg := sprintf("KafkaTopic name '%s' is invalid: %s. Example of valid name: 'demo-topic-123'", [name, reason])
}

# Deny if any topic in an array is missing metadata
deny[msg] {
    some i
    topic := input[i]
    topic.kind == "KafkaTopic"
    not topic.metadata
    msg := sprintf("KafkaTopic at index %d is missing required 'metadata' field", [i])
}

# Deny if any topic in an array is missing the name field
deny[msg] {
    some i
    topic := input[i]
    topic.kind == "KafkaTopic"
    topic.metadata
    not topic.metadata.name
    msg := sprintf("KafkaTopic at index %d is missing required 'name' field", [i])
}

# Deny if any topic in an array of topics has an invalid name
deny[msg] {
    some i
    topic := input[i]
    topic.kind == "KafkaTopic"
    topic.metadata.name
    name := topic.metadata.name
    not valid_topic_name(name)
    reason := get_validation_error(name)
    msg := sprintf("KafkaTopic at index %d with name '%s' is invalid: %s. Example of valid name: 'demo-topic-123'", [i, name, reason])
}

# Helper function to validate the name
valid_topic_name(name) {
    re_match("^demo-topic-[0-9]+$", name)
}

# Helper function to determine the specific validation error
get_validation_error(name) = reason {
    name == ""
    reason := "name cannot be empty"
}

get_validation_error(name) = reason {
    name != ""
    not startswith(name, "demo-topic-")
    reason := "must start with 'demo-topic-'"
}

get_validation_error(name) = reason {
    name != ""
    startswith(name, "demo-topic-")
    not re_match("^demo-topic-[0-9]+$", name)
    reason := "must end with one or more digits after 'demo-topic-'"
}
