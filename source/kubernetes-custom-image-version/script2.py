from locust import HttpUser, task, between

class test(HttpUser):
    wait_time = between(2, 4)

    @task
    def initial_request(self):
        self.client.get("/")