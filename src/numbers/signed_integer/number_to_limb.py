class Limb128:
    def __init__(self, low, high, sign):
        self.low = low
        self.high = high
        self.sign = sign

    def __str__(self):
        return f"Sign: {self.sign}, Low: {self.low}, High: {self.high}"

def create_limb128_representation(number):
    if number < 0:
        sign = True
        number = abs(number)
    else:
        sign = False

    low = number & ((1 << 128) - 1)
    high = (number >> 128) & ((1 << 128) - 1)

    return Limb128(low, high, sign)


# Ejemplo de uso:
numero = -14152656782020732463081131957909171480836778  # Número con signo negativo
limb_objeto = create_limb128_representation(numero)
print(limb_objeto)
