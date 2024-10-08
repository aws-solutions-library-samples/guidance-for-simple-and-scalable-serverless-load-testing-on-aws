from locust import HttpUser, task, between

class test(HttpUser):
    wait_time = between(1, 3)

    @task
    def initial_request(self):
        self.client.get("/")