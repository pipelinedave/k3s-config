# Copilot Todo Manager Instructions

## Automatic Todo Processing

Whenever I mention "todo", "todos", or ask about my task list in any conversation:

1. Automatically check the `.github/todo/Todo.md` file for changes
2. Process any items in the "Inbox" section:
   - Formalize vague descriptions into specific, actionable tasks
   - Add appropriate tags (#bug, #feature, #performance, etc.)
   - Move them to the appropriate priority section under "Organized Tasks"
3. Update the Todo.md file with the improved structure
4. Preserve any items I've manually placed in specific sections
5. Always maintain the "Inbox" section so I can freely add new items

When suggesting tasks to work on, prioritize based on:

1. Items marked high priority
2. Dependencies between tasks
3. Logical grouping of related work

Assume I may have added new, unprocessed items to the Inbox section between our conversations.

## User Preferences

- Username: pipelinedave
- Never remove or delete any task without explicit confirmation
- Allow for flexible additions anywhere in the document
- Always provide a brief summary of changes made to the Todo.md
