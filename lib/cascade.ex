defmodule Dissentr.Cascade do
  use Supervisor.Behaviour

  def add_node(name, next, key_number) do
    Dissentr.Cascade.start_link({ name, next, "example_data/pub#{key_number}.pem",
                                              "example_data/priv#{key_number}.pem" })
  end

  def start_link(state) do
    :supervisor.start_link( __MODULE__, state)
  end

  def init({name, target, public_keyfile, private_keyfile}) do
    node = worker(Dissentr.Node, [name,
                                  { target,
                                    public_keyfile,
                                    private_keyfile }])

    supervise( [ node ], strategy: :one_for_one)
  end

  def mix(name, message) do
    public_keys = :gen_server.call({ :global, name }, :public_keys)
    { cipher_text, encrypted_keys } = encrypt(public_keys, message)

    :gen_server.cast({ :global, name }, {:handle, cipher_text, encrypted_keys})
  end

  def encrypt([], message) do
    { message, [] }
  end

  def encrypt([key|next_keys], message) do
    { cipher_text, encrypted_key } = CryptoHybrid.encrypt_hybrid(message, key)
    { final_text, keys }           = encrypt(next_keys, cipher_text)

    { final_text, keys ++ [encrypted_key] }
  end
end