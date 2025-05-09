# Global Copilot Instructions

## Todo Management
- Always check for the file `.github/copilot/Todo.md` in this repository.
- Process the todo list based on the instructions in `.github/copilot/CopilotTodo.md`.
- Maintain the structure of the todo list while allowing me to freely add new items anywhere.
- Help me prioritize and work on tasks from the todo list.


# GitHub Copilot Context for Choremane

## Project Overview
Choremane is a Vue 3 PWA for chore management using Material You design system.

## Key Conventions
- Use Composition API with `script setup` syntax
- Follow kebab-case for files/folders, PascalCase for components
- Stores are named `somethingStore.js`
- Components must be small and focused
- Pinia is used for state management
- Material You theming with CSS variables

## Common Patterns
- Wrap API calls in try/catch with log system integration
- Use composables for shared logic
- PWA features require service worker considerations
- Authentication flows use Dex OAuth2
- Swipe gestures using Hammer.js
- Log entries for all state changes
- Notification scheduling via setInterval

## Data Structures
```typescript
interface Chore {
  id: string
  name: string
  due_date: string
  interval_days: number
  done: boolean
  done_by: string | null
  archived: boolean
  owner_email: string | null
  is_private: boolean
}

interface LogEntry {
  id: string
  action: string
  timestamp: Date
  undoable: boolean
  chore_id?: string
  action_details?: Record<string, any>
}

interface NotificationSettings {
  enabled: boolean
  times: string[]
}
```

## Testing Conventions
- Component tests should use Vue Test Utils
- Store tests should verify persistence
- Mock service worker responses for offline testing
- E2E tests with Cypress for critical flows
