from rest_framework.pagination import CursorPagination

class PKOrderedCursorPagination(CursorPagination):
    """
    Cursor pagination can be used to improve response time
    by removing the elements count from all responses.
    """
    ordering = 'pk'
    page_size = 100
    page_size_query_param = 'page_size'
