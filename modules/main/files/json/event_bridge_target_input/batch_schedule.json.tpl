{
  "JobName": "${job_name}",
  "JobDefinition": "${job_definition}",
  "JobQueue": "${job_queue}",
  "EcsPropertiesOverride": {
    "TaskProperties": [
      {
        "Containers": [
          {
            "Name": "${container_name}",
            "Command": ["bash", "-c", "$$COMMAND"],
            "Environment": [
              {
                "Name": "COMMAND",
                "Value": "${job_command}"
              }
            ],
            "ResourceRequirements": [
              {
                "Type": "VCPU",
                "Value": "${vcpu}"
              },
              {
                "Type": "MEMORY",
                "Value": "${memory}"
              }
            ]
          }
        ]
      }
    ]
  }
}