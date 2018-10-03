import logging
import os
import sys

from locust import Locust
from locust import TaskSet
from locust import task

from locust import HttpLocust

logger = logging.getLogger("dummy_locust")

# class MyTaskSet(TaskSet):

#     @task
#     def my_task(self):
#         print('Locust instance (%r) executing "my_task"'.format(self.locust))


# class MyLocust(Locust):
#     task_set = MyTaskSet


class ActionsTaskSet(TaskSet):
    """
    This is a container class that holds all locust load tests we want to run sequentally
    """

    @task
    def index(self):
        """Hit https://example.com/ endpoint
        Arguments:
            N/A
        Decorators:
            task
        """

        response = self.client.get("/")
        logger.info("Response status code: {}".format(response.status_code))

        if VERBOSE_LOGS:
            logger.debug("Response content: {}".format(response.content))


class MyLocust(HttpLocust):
    """Locust action wrapper class, this is what actually performs the load tests
        Arguments:
            N/A
        Decorators:
            task
    """

    weight = 1
    task_set = ActionsTaskSet
    min_wait = 2000
    max_wait = 9000
    # host = DOMAIN
