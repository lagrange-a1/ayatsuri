mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */
use flutter_rust_bridge::frb;

#[frb]
#[derive(Debug, Clone)]
pub struct Task {
    pub id: u64,
    pub latency: u64,
}

#[frb(opaque)]
pub struct Scheduler {
    tasks: Vec<Task>,
}

#[frb]
impl Scheduler {
    pub fn new() -> Self {
        Scheduler { tasks: Vec::new() }
    }

    pub fn add_task(&mut self, task: Task) {
        self.tasks.push(task);
    }

    pub fn next_task(&mut self) -> Option<Task> {
        if self.tasks.is_empty() {
            return None;
        }
        let mut min_idx = 0;
        for (i, task) in self.tasks.iter().enumerate() {
            if task.latency < self.tasks[min_idx].latency {
                min_idx = i;
            }
        }
        let task = self.tasks.remove(min_idx);
        Some(task)
    }

    pub fn remove_task(&mut self, id: u64) -> bool {
        if let Some(pos) = self.tasks.iter().position(|t| t.id == id) {
            self.tasks.remove(pos);
            true
        } else {
            false
        }
    }
}

#[frb(start)]
pub fn scheduler_lib_init() {
    // initialization code if needed
}
