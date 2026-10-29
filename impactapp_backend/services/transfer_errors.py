class TransferError(Exception):
    def __init__(self, code, status=400, message=None):
        super().__init__(code)
        self.code = code
        self.status = status
        self.message = message or code
