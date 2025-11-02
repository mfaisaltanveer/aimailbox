defmodule Aimailbox.Encrypted do
  use Cloak.Vault, otp_app: :aimailbox
end

defmodule Aimailbox.Encrypted.Binary do
  use Cloak.Ecto.Binary, vault: Aimailbox.Encrypted
end
