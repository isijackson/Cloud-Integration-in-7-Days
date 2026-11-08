from locust import HttpUser, task, between
class PassBuyer(HttpUser):
    wait_time = between(1, 3)
    @task(5)
    def home(self):
        self.client.get('/')
    @task(1)
    def static(self):
        self.client.get('/static.txt')
    @task(4)
    def buy(self):
        # the CPU-bound checkout: this is what makes the group scale
        self.client.get('/buy')
