class Field:
	def __init__(self, width, height):
		self.width = width
		self.height = height

		self.bot = 0
		self.top = 19
		self.left = 0
		self.right = 9

		self.field = []
		self.set_field()

	def set_field(self):
		for i in range(self.height):
			self.field.append([0] * self.width)