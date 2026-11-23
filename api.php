<?php
declare(strict_types=1);
require __DIR__ . '/api/db.php';
if (session_status() !== PHP_SESSION_ACTIVE) {
    ini_set('session.use_strict_mode','1');
    session_set_cookie_params(['lifetime'=>0,'path'=>'/','secure'=>!empty($_SERVER['HTTPS'])&&$_SERVER['HTTPS']!=='off','httponly'=>true,'samesite'=>'Lax']);
    session_start();
}

$action = $_GET['action'] ?? '';
$method = $_SERVER['REQUEST_METHOD'];

try {
    if ($action === 'login' && $method === 'POST') {
        $data = input();
        $stmt = db()->prepare('SELECT id, nome, email, senha_hash, perfil FROM usuarios WHERE email = ? AND ativo = 1 LIMIT 1');
        $stmt->execute([strtolower(trim((string)($data['email'] ?? '')))]);
        $user = $stmt->fetch();
        if (!$user) {
            $reference = bin2hex(random_bytes(4));
            error_log(sprintf('[restaurante-auth][%s] failure=account_not_found_or_inactive', $reference));
            json_response(['error' => 'Falha no login.', 'reference' => $reference], 422);
        }
        if (!password_verify((string)($data['senha'] ?? ''), $user['senha_hash'])) {
            $reference = bin2hex(random_bytes(4));
            $hashInfo = password_get_info($user['senha_hash']);
            error_log(sprintf(
                '[restaurante-auth][%s] failure=password_mismatch user_id=%d hash_length=%d algorithm=%s',
                $reference,
                (int)$user['id'],
                strlen((string)$user['senha_hash']),
                $hashInfo['algoName'] ?? 'unknown'
            ));
            json_response(['error' => 'Falha no login.', 'reference' => $reference], 422);
        }
        if (!$user || !password_verify((string)($data['senha'] ?? ''), $user['senha_hash'])) json_response(['error' => 'E-mail ou senha inválidos.'], 422);
        session_regenerate_id(true); unset($user['senha_hash']); $_SESSION['user'] = $user; $_SESSION['csrf_token']=bin2hex(random_bytes(32));
        json_response(['user' => $user,'csrf_token'=>$_SESSION['csrf_token']]);
    }
    if ($action === 'logout' && $method==='POST') { require_login(); verify_csrf(); session_unset(); session_destroy(); json_response(['ok' => true]); }
    if ($action === 'me') { if(!empty($_SESSION['user'])&&empty($_SESSION['csrf_token']))$_SESSION['csrf_token']=bin2hex(random_bytes(32)); json_response(['user' => $_SESSION['user'] ?? null,'csrf_token'=>$_SESSION['csrf_token']??null]); }
    $user = require_login();
    require_permission($user,$action,$method,$_GET);
    if ($method==='POST') verify_csrf();
    $pdo = db();

    if ($action === 'dashboard') {
        $products = (int)$pdo->query('SELECT COUNT(*) FROM produtos WHERE ativo = 1')->fetchColumn();
        $recipes = (int)$pdo->query("SELECT COUNT(*) FROM fichas_tecnicas WHERE status <> 'arquivada'")->fetchColumn();
        $waste = (float)$pdo->query("SELECT COALESCE(SUM(valor_estimado),0) FROM desperdicios WHERE data_registro >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)")->fetchColumn();
        $recent = $pdo->query('SELECT d.data_registro, p.nome produto, d.quantidade, d.unidade, d.motivo, d.valor_estimado FROM desperdicios d JOIN produtos p ON p.id=d.produto_id ORDER BY d.id DESC LIMIT 8')->fetchAll();
        json_response(compact('products', 'recipes', 'waste', 'recent'));
    }
    if ($action === 'users') {
        if (($user['perfil']??'')!=='admin') json_response(['error'=>'Somente administrador pode gerenciar usuários.'],403);
        if ($method==='GET') json_response(['items'=>$pdo->query('SELECT id,nome,email,perfil,ativo,criado_em FROM usuarios ORDER BY nome')->fetchAll()]);
        $d=input();$name=trim((string)($d['nome']??''));$email=strtolower(trim((string)($d['email']??'')));$role=(string)($d['perfil']??'operacional');
        if($name===''||!filter_var($email,FILTER_VALIDATE_EMAIL)||!in_array($role,['admin','gestor','cozinha','compras','operacional'],true))json_response(['error'=>'Revise nome, e-mail e perfil.'],422);
        if(!empty($d['id'])){$id=(int)$d['id'];$active=!empty($d['ativo'])?1:0;if($id===(int)$user['id']&&(!$active||$role!=='admin'))json_response(['error'=>'Não é possível remover seu próprio acesso de administrador.'],422);$stmt=$pdo->prepare('UPDATE usuarios SET nome=?,email=?,perfil=?,ativo=? WHERE id=?');$stmt->execute([$name,$email,$role,$active,$id]);if(!empty($d['senha'])){if(strlen((string)$d['senha'])<8)json_response(['error'=>'A senha deve ter pelo menos 8 caracteres.'],422);$pdo->prepare('UPDATE usuarios SET senha_hash=? WHERE id=?')->execute([password_hash((string)$d['senha'],PASSWORD_DEFAULT),$id]);}audit((int)$user['id'],'atualizou','usuario',$id,['perfil'=>$role,'ativo'=>$active]);json_response(['id'=>$id,'updated'=>true]);}
        $password=(string)($d['senha']??'');if(strlen($password)<8)json_response(['error'=>'A senha deve ter pelo menos 8 caracteres.'],422);$stmt=$pdo->prepare('INSERT INTO usuarios(nome,email,senha_hash,perfil) VALUES(?,?,?,?)');$stmt->execute([$name,$email,password_hash($password,PASSWORD_DEFAULT),$role]);$id=(int)$pdo->lastInsertId();audit((int)$user['id'],'criou','usuario',$id,['perfil'=>$role]);json_response(['id'=>$id],201);
    }
    if ($action === 'products') {
        if ($method === 'GET') json_response(['items' => $pdo->query("SELECT p.*, c.nome categoria, f.nome fornecedor FROM produtos p LEFT JOIN categorias_produto c ON c.id=p.categoria_id LEFT JOIN fornecedores f ON f.id=p.fornecedor_principal_id WHERE p.ativo=1 ORDER BY p.nome")->fetchAll()]);
        $d = input();
        $stmt = $pdo->prepare('INSERT INTO produtos (nome, codigo, categoria_id, marca, unidade_compra, unidade_consumo, fator_conversao, rendimento_percentual, estoque_minimo, estoque_maximo, validade_padrao_dias, preco_atual, fornecedor_principal_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
        $stmt->execute([$d['nome'], $d['codigo'] ?: null, $d['categoria_id'] ?: null, $d['marca'] ?: null, $d['unidade_compra'], $d['unidade_consumo'], (float)($d['fator_conversao'] ?: 1), (float)($d['rendimento_percentual'] ?: 100), (float)($d['estoque_minimo'] ?: 0), ($d['estoque_maximo']??'')!==''?(float)$d['estoque_maximo']:null, ($d['validade_padrao_dias']??'')!==''?(int)$d['validade_padrao_dias']:null, (float)($d['preco_atual'] ?: 0), $d['fornecedor_id'] ?: null]);
        $id=(int)$pdo->lastInsertId();
        $conversion=product_conversion((string)$d['unidade_compra'],(string)$d['unidade_consumo'],(float)($d['fator_conversao']?:1));
        if ((float)($d['preco_atual']??0)>0) { $h=$pdo->prepare("INSERT INTO historico_precos(produto_id,fornecedor_id,preco,unidade,quantidade_base,quantidade_compra,origem,usuario_id) VALUES(?,?,?,?,?,1,'cadastro',?)");$h->execute([$id,$d['fornecedor_id']?:null,(float)$d['preco_atual'],$d['unidade_compra'],$conversion,(int)$user['id']]); }
        if (!empty($d['fornecedor_id'])) { $l=$pdo->prepare('INSERT IGNORE INTO produto_fornecedores(produto_id,fornecedor_id,preferencial) VALUES(?,?,1)');$l->execute([$id,(int)$d['fornecedor_id']]); }
        audit((int)$user['id'], 'criou', 'produto', $id, $d); json_response(['id'=>$id], 201);
    }
    if ($action === 'suppliers') {
        if ($method === 'GET') {
            $items=$pdo->query('SELECT f.*, COUNT(p.id) produtos_vinculados FROM fornecedores f LEFT JOIN produtos p ON p.fornecedor_principal_id=f.id AND p.ativo=1 WHERE f.ativo=1 GROUP BY f.id ORDER BY f.nome')->fetchAll();
            foreach ($items as &$supplier) {
                $stmt=$pdo->prepare('SELECT id,nome,marca,preco_atual,unidade_compra FROM produtos WHERE fornecedor_principal_id=? AND ativo=1 ORDER BY nome');
                $stmt->execute([$supplier['id']]); $supplier['produtos']=$stmt->fetchAll();
            }
            json_response(['items'=>$items]);
        }
        $d=input(); $name=trim((string)($d['nome']??''));
        if ($name==='') json_response(['error'=>'Informe o nome do fornecedor.'],422);
        if (!empty($d['id'])) {
            $id=(int)$d['id'];
            $stmt=$pdo->prepare('UPDATE fornecedores SET nome=?,documento=?,telefone=?,contato=? WHERE id=? AND ativo=1');
            $stmt->execute([$name,trim((string)($d['documento']??''))?:null,trim((string)($d['telefone']??''))?:null,trim((string)($d['contato']??''))?:null,$id]);
            if ($stmt->rowCount()===0) {
                $check=$pdo->prepare('SELECT id FROM fornecedores WHERE id=? AND ativo=1'); $check->execute([$id]);
                if (!$check->fetch()) json_response(['error'=>'Fornecedor não encontrado.'],404);
            }
            audit((int)$user['id'],'atualizou','fornecedor',$id,$d); json_response(['id'=>$id,'updated'=>true]);
        }
        $stmt=$pdo->prepare('INSERT INTO fornecedores (nome,documento,telefone,contato) VALUES (?,?,?,?)');
        $stmt->execute([$name,trim((string)($d['documento']??''))?:null,trim((string)($d['telefone']??''))?:null,trim((string)($d['contato']??''))?:null]);
        $id=(int)$pdo->lastInsertId(); audit((int)$user['id'],'criou','fornecedor',$id,$d); json_response(['id'=>$id],201);
    }
    if ($action === 'cost_settings') {
        if ($method==='GET') { $row=$pdo->query('SELECT p.regra_preco,p.regra_id,r.nome regra_nome FROM parametros_custo p LEFT JOIN regras_custo r ON r.id=p.regra_id WHERE p.id=1')->fetch();$rules=$pdo->query('SELECT id,nome,metodo,sistema FROM regras_custo ORDER BY sistema DESC,nome')->fetchAll();json_response(['regra_preco'=>$row['regra_preco']??'ultimo','regra_id'=>$row['regra_id']??null,'regra_nome'=>$row['regra_nome']??'Ultimo preco efetivo','rules'=>$rules]); }
        if (!in_array($user['perfil'],['admin','gestor'],true)) json_response(['error'=>'Somente administrador ou gestor pode alterar esta configuração.'],403);
        $d=input();
        if (($d['modo']??'')==='criar') { $name=trim((string)($d['nome']??''));$method=(string)($d['metodo']??'');$nameLength=preg_match_all('/./us',$name,$nameChars);if($nameLength===false||$nameLength<2||$nameLength>80||!in_array($method,['ultimo','media_ponderada'],true))json_response(['error'=>'Informe um nome de até 80 caracteres e um método válido.'],422);$stmt=$pdo->prepare('INSERT INTO regras_custo(nome,metodo,sistema,criado_por) VALUES(?,?,0,?)');try{$stmt->execute([$name,$method,(int)$user['id']]);}catch(PDOException $e){if((string)$e->getCode()==='23000')json_response(['error'=>'Já existe uma regra com esse nome.'],409);throw $e;}$id=(int)$pdo->lastInsertId();$pdo->prepare('INSERT INTO parametros_custo(id,regra_preco,regra_id,atualizado_por) VALUES(1,?,?,?) ON DUPLICATE KEY UPDATE regra_preco=VALUES(regra_preco),regra_id=VALUES(regra_id),atualizado_por=VALUES(atualizado_por)')->execute([$method,$id,(int)$user['id']]);audit((int)$user['id'],'criou','regra_custo',$id,['nome'=>$name,'metodo'=>$method]);json_response(['id'=>$id,'nome'=>$name,'metodo'=>$method],201); }
        $id=(int)($d['regra_id']??0);$stmt=$pdo->prepare('SELECT id,nome,metodo FROM regras_custo WHERE id=?');$stmt->execute([$id]);$rule=$stmt->fetch();if(!$rule)json_response(['error'=>'Regra de custo não encontrada.'],404);$pdo->prepare('INSERT INTO parametros_custo(id,regra_preco,regra_id,atualizado_por) VALUES(1,?,?,?) ON DUPLICATE KEY UPDATE regra_preco=VALUES(regra_preco),regra_id=VALUES(regra_id),atualizado_por=VALUES(atualizado_por)')->execute([$rule['metodo'],$id,(int)$user['id']]);audit((int)$user['id'],'selecionou','regra_custo',$id);json_response(['regra_id'=>$id,'regra_preco'=>$rule['metodo'],'regra_nome'=>$rule['nome']]);
    }
    if ($action === 'price_history' && $method==='GET') {
        $productId=(int)($_GET['produto_id']??0);$stmt=$pdo->prepare('SELECT h.*,f.nome fornecedor,u.nome usuario FROM historico_precos h LEFT JOIN fornecedores f ON f.id=h.fornecedor_id JOIN usuarios u ON u.id=h.usuario_id WHERE h.produto_id=? ORDER BY h.registrado_em DESC,h.id DESC LIMIT 200');$stmt->execute([$productId]);json_response(['items'=>$stmt->fetchAll()]);
    }
    if ($action === 'purchases') {
        if ($method==='GET') { $items=$pdo->query('SELECT c.*,f.nome fornecedor,u.nome usuario,(SELECT COUNT(*) FROM compra_itens i WHERE i.compra_id=c.id) itens FROM compras c JOIN fornecedores f ON f.id=c.fornecedor_id JOIN usuarios u ON u.id=c.usuario_id ORDER BY c.data_compra DESC,c.id DESC LIMIT 100')->fetchAll();json_response(['items'=>$items]); }
        $d=input();$items=$d['itens']??[];if(empty($d['fornecedor_id'])||!count($items))json_response(['error'=>'Informe fornecedor e ao menos um item.'],422);
        $pdo->beginTransaction();$stmt=$pdo->prepare("INSERT INTO compras(fornecedor_id,data_compra,referencia,status,desconto_total,frete_total,observacoes,usuario_id) VALUES(?,?,?,'rascunho',?,?,?,?)");$stmt->execute([(int)$d['fornecedor_id'],$d['data_compra']??date('Y-m-d H:i:s'),$d['referencia']?:null,(float)($d['desconto_total']??0),(float)($d['frete_total']??0),$d['observacoes']?:null,(int)$user['id']]);$id=(int)$pdo->lastInsertId();
        $line=$pdo->prepare('INSERT INTO compra_itens(compra_id,produto_id,quantidade,unidade,preco_unitario,desconto,lote,validade) VALUES(?,?,?,?,?,?,?,?)');foreach($items as $i){$qty=(float)($i['quantidade']??0);$price=(float)($i['preco_unitario']??0);if($qty<=0||$price<0)throw new InvalidArgumentException('Quantidade deve ser positiva e preço não negativo.');$line->execute([$id,(int)$i['produto_id'],$qty,(string)$i['unidade'],$price,(float)($i['desconto']??0),$i['lote']?:null,$i['validade']?:null]);}
        $pdo->commit();audit((int)$user['id'],'criou','compra',$id,$d);json_response(['id'=>$id],201);
    }
    if ($action === 'purchase_detail' && $method==='GET') { $id=(int)($_GET['id']??0);$stmt=$pdo->prepare('SELECT c.*,f.nome fornecedor,f.telefone,u.nome usuario FROM compras c JOIN fornecedores f ON f.id=c.fornecedor_id JOIN usuarios u ON u.id=c.usuario_id WHERE c.id=?');$stmt->execute([$id]);$purchase=$stmt->fetch();if(!$purchase)json_response(['error'=>'Compra não encontrada.'],404);$items=$pdo->prepare('SELECT i.*,p.nome produto,p.unidade_consumo FROM compra_itens i JOIN produtos p ON p.id=i.produto_id WHERE i.compra_id=? ORDER BY i.id');$items->execute([$id]);$purchase['itens']=$items->fetchAll();$purchase['valor_itens']=array_sum(array_map(static fn($item)=>(float)$item['quantidade']*(float)$item['preco_unitario']-(float)$item['desconto'],$purchase['itens']));$purchase['total_estimado']=$purchase['valor_itens']-(float)$purchase['desconto_total']+(float)$purchase['frete_total'];json_response($purchase); }
    if ($action === 'purchase_receive' && $method==='POST') {
        $d=input();$id=(int)($d['id']??0);$pdo->beginTransaction();$find=$pdo->prepare("SELECT * FROM compras WHERE id=? AND status='rascunho' FOR UPDATE");$find->execute([$id]);$purchase=$find->fetch();if(!$purchase)json_response(['error'=>'Compra não encontrada ou já processada.'],404);
        $lines=$pdo->prepare('SELECT i.*,p.fator_conversao,p.unidade_compra,p.unidade_consumo FROM compra_itens i JOIN produtos p ON p.id=i.produto_id WHERE i.compra_id=?');$lines->execute([$id]);$items=$lines->fetchAll();$gross=0;foreach($items as $item)$gross+=(float)$item['quantidade']*(float)$item['preco_unitario'];
        foreach($items as $item){$qty=(float)$item['quantidade'];$lineGross=$qty*(float)$item['preco_unitario'];$allocatedDiscount=(float)$purchase['desconto_total']*($gross>0?$lineGross/$gross:0);$allocatedFreight=(float)$purchase['frete_total']*($gross>0?$lineGross/$gross:0);$effective=max(0,$lineGross-(float)$item['desconto']-$allocatedDiscount+$allocatedFreight);$lineUnitPrice=$effective/$qty;$factor=product_line_conversion($item['unidade'],$item['unidade_compra'],$item['unidade_consumo'],(float)$item['fator_conversao']);$baseQty=$qty*$factor;$purchaseFactor=product_conversion($item['unidade_compra'],$item['unidade_consumo'],(float)$item['fator_conversao']);$purchaseQty=$baseQty/$purchaseFactor;$normalizedPrice=$effective/$purchaseQty;
            $h=$pdo->prepare("INSERT INTO historico_precos(produto_id,fornecedor_id,compra_item_id,preco,unidade,quantidade_base,quantidade_compra,origem,usuario_id) VALUES(?,?,?,?,?,?,?, 'compra',?)");$h->execute([(int)$item['produto_id'],(int)$purchase['fornecedor_id'],(int)$item['id'],$normalizedPrice,$item['unidade_compra'],$baseQty,$purchaseQty,(int)$user['id']]);$historyId=(int)$pdo->lastInsertId();
            $rule=$pdo->query('SELECT regra_preco FROM parametros_custo WHERE id=1')->fetchColumn()?:'ultimo';$newPrice=$normalizedPrice;
            if($rule==='media_ponderada'){$old=$pdo->prepare('SELECT SUM(preco*quantidade_compra)/NULLIF(SUM(quantidade_compra),0) FROM historico_precos WHERE produto_id=?');$old->execute([(int)$item['produto_id']]);$avg=$old->fetchColumn();if($avg!==null)$newPrice=(float)$avg;}
            $update=$pdo->prepare('UPDATE produtos SET preco_atual=?,fornecedor_principal_id=? WHERE id=?');$update->execute([$newPrice,(int)$purchase['fornecedor_id'],(int)$item['produto_id']]);$link=$pdo->prepare('INSERT IGNORE INTO produto_fornecedores(produto_id,fornecedor_id) VALUES(?,?)');$link->execute([(int)$item['produto_id'],(int)$purchase['fornecedor_id']]);
            $move=$pdo->prepare("INSERT INTO movimentacoes_estoque(produto_id,tipo,quantidade_base,unidade_base,custo_unitario,lote,validade,origem_tipo,origem_id,usuario_id) VALUES(?,'entrada',?,?,?,?,?,'compra',?,?)");$move->execute([(int)$item['produto_id'],$baseQty,$item['unidade_consumo'],$newPrice/$purchaseFactor,$item['lote'],$item['validade'],$id,(int)$user['id']]);
        }
        $pdo->prepare("UPDATE compras SET status='recebida',recebida_em=NOW() WHERE id=?")->execute([$id]);$pdo->commit();audit((int)$user['id'],'recebeu','compra',$id);json_response(['ok'=>true]);
    }
    if ($action === 'stock') {
        if ($method==='GET') { $items=$pdo->query("SELECT p.id,p.nome,p.unidade_consumo,p.estoque_minimo,p.estoque_maximo,p.preco_atual,COALESCE(SUM(CASE WHEN m.tipo IN ('entrada','devolucao','transferencia_entrada') THEN m.quantidade_base WHEN m.tipo IN ('consumo','perda','transferencia_saida') THEN -m.quantidade_base ELSE m.quantidade_base END),0) saldo FROM produtos p LEFT JOIN movimentacoes_estoque m ON m.produto_id=p.id AND m.local_id=1 WHERE p.ativo=1 GROUP BY p.id ORDER BY p.nome LIMIT 500")->fetchAll();json_response(['items'=>$items]); }
        $d=input();$productId=(int)($d['produto_id']??0);$qty=(float)($d['quantidade']??0);if(!$productId||$qty==0)json_response(['error'=>'Informe produto e quantidade de ajuste diferente de zero.'],422);$p=$pdo->prepare('SELECT unidade_consumo,fator_conversao,unidade_compra FROM produtos WHERE id=?');$p->execute([$productId]);$product=$p->fetch();if(!$product)json_response(['error'=>'Produto não encontrado.'],404);if(stock_balance($pdo,$productId,1)+$qty<-.00001)json_response(['error'=>'O ajuste deixaria o estoque negativo. Confira o saldo ou registre uma entrada.'],422);$stmt=$pdo->prepare("INSERT INTO movimentacoes_estoque(produto_id,tipo,quantidade_base,unidade_base,origem_tipo,observacoes,usuario_id) VALUES(?,'ajuste',? ,?,'ajuste',?,?)");$stmt->execute([$productId,$qty,$product['unidade_consumo'],$d['observacoes']??null,(int)$user['id']]);audit((int)$user['id'],'ajustou','estoque',(int)$pdo->lastInsertId(),$d);json_response(['ok'=>true],201);
    }
    if ($action === 'inventory' && $method==='GET') { json_response(['items'=>$pdo->query('SELECT i.*,l.nome local,u.nome usuario FROM inventarios i JOIN locais_estoque l ON l.id=i.local_id JOIN usuarios u ON u.id=i.usuario_id ORDER BY i.iniciado_em DESC LIMIT 100')->fetchAll()]); }
    if ($action === 'inventory' && $method==='POST') {
        $d=input();$location=(int)($d['local_id']??1);$pdo->beginTransaction();$stmt=$pdo->prepare("INSERT INTO inventarios(local_id,status,usuario_id,observacoes) VALUES(?,'aberto',?,?)");$stmt->execute([$location,(int)$user['id'],$d['observacoes']??null]);$id=(int)$pdo->lastInsertId();$balances=$pdo->query("SELECT p.id,p.unidade_consumo,COALESCE(SUM(CASE WHEN m.tipo IN ('entrada','devolucao','transferencia_entrada') THEN m.quantidade_base WHEN m.tipo IN ('consumo','perda','transferencia_saida') THEN -m.quantidade_base ELSE m.quantidade_base END),0) saldo FROM produtos p LEFT JOIN movimentacoes_estoque m ON m.produto_id=p.id AND m.local_id=$location WHERE p.ativo=1 GROUP BY p.id")->fetchAll();$item=$pdo->prepare('INSERT INTO inventario_itens(inventario_id,produto_id,saldo_sistema,unidade_base) VALUES(?,?,?,?)');foreach($balances as $b)$item->execute([$id,$b['id'],$b['saldo'],$b['unidade_consumo']]);$pdo->commit();json_response(['id'=>$id],201);
    }
    if ($action === 'inventory_detail' && $method==='GET') { $id=(int)($_GET['id']??0);$stmt=$pdo->prepare('SELECT i.*,p.nome produto FROM inventario_itens i JOIN produtos p ON p.id=i.produto_id WHERE i.inventario_id=? ORDER BY p.nome');$stmt->execute([$id]);json_response(['items'=>$stmt->fetchAll()]); }
    if ($action === 'inventory_count' && $method==='POST') {
        $d=input();$id=(int)($d['id']??0);$items=$d['itens']??[];$pdo->beginTransaction();$check=$pdo->prepare("SELECT id FROM inventarios WHERE id=? AND status='aberto' FOR UPDATE");$check->execute([$id]);if(!$check->fetch())json_response(['error'=>'Inventário não está aberto.'],409);$expected=$pdo->prepare('SELECT COUNT(*) FROM inventario_itens WHERE inventario_id=?');$expected->execute([$id]);if(count($items)!==(int)$expected->fetchColumn())json_response(['error'=>'Informe a contagem de todos os produtos do inventário antes de salvar.'],422);$update=$pdo->prepare('UPDATE inventario_itens SET quantidade_contada=? WHERE inventario_id=? AND produto_id=?');foreach($items as $item){$qty=(float)($item['quantidade']??-1);if($qty<0)throw new InvalidArgumentException('A contagem não pode ser negativa.');$update->execute([$qty,$id,(int)$item['produto_id']]);}$pdo->prepare("UPDATE inventarios SET status='contado',contado_em=NOW() WHERE id=?")->execute([$id]);$pdo->commit();json_response(['ok'=>true]);
    }
    if ($action === 'inventory_approve' && $method==='POST') {
        $d=input();$id=(int)($d['id']??0);$pdo->beginTransaction();$check=$pdo->prepare("SELECT * FROM inventarios WHERE id=? AND status='contado' FOR UPDATE");$check->execute([$id]);if(!$check->fetch())json_response(['error'=>'Inventário ainda não foi contado.'],409);$stmt=$pdo->prepare('SELECT i.*,p.preco_atual,p.unidade_compra,p.fator_conversao FROM inventario_itens i JOIN produtos p ON p.id=i.produto_id WHERE i.inventario_id=? AND i.quantidade_contada IS NOT NULL');$stmt->execute([$id]);foreach($stmt->fetchAll() as $item){$diff=(float)$item['quantidade_contada']-(float)$item['saldo_sistema'];if(abs($diff)>0.00001){$m=$pdo->prepare("INSERT INTO movimentacoes_estoque(produto_id,tipo,quantidade_base,unidade_base,custo_unitario,origem_tipo,origem_id,usuario_id,observacoes) VALUES(?,'ajuste',?,?,?,'inventario',?,?, 'Ajuste após contagem')");$m->execute([(int)$item['produto_id'],$diff,$item['unidade_base'],(float)$item['preco_atual']/product_conversion($item['unidade_compra'],$item['unidade_base'],(float)$item['fator_conversao']),$id,(int)$user['id']]);}}$pdo->prepare("UPDATE inventarios SET status='aprovado',aprovado_em=NOW(),aprovado_por=? WHERE id=?")->execute([(int)$user['id'],$id]);$pdo->commit();audit((int)$user['id'],'aprovou','inventario',$id);json_response(['ok'=>true]);
    }
    if ($action === 'production' && $method==='GET') { json_response(['items'=>$pdo->query('SELECT p.*,f.nome ficha,u.nome responsavel FROM producoes p JOIN fichas_tecnicas f ON f.id=p.ficha_id JOIN usuarios u ON u.id=p.responsavel_id ORDER BY p.registrada_em DESC LIMIT 100')->fetchAll()]); }
    if ($action === 'production_detail' && $method==='GET') { $stmt=$pdo->prepare('SELECT p.*,f.nome ficha,f.codigo ficha_codigo,f.rendimento_total,f.unidade_rendimento,f.versao ficha_versao,u.nome responsavel,u.email responsavel_email FROM producoes p JOIN fichas_tecnicas f ON f.id=p.ficha_id JOIN usuarios u ON u.id=p.responsavel_id WHERE p.id=?');$stmt->execute([(int)($_GET['id']??0)]);$item=$stmt->fetch();if(!$item)json_response(['error'=>'Registro de produção não encontrado.'],404);json_response($item); }
    if ($action === 'production' && $method==='POST') { $d=input();$stmt=$pdo->prepare("INSERT INTO producoes(ficha_id,quantidade_planejada,unidade,turno,responsavel_id,observacoes) VALUES(?,?,?,?,?,?)");$stmt->execute([(int)$d['ficha_id'],(float)$d['quantidade_planejada'],$d['unidade'],trim((string)($d['turno']??''))?:null,(int)$user['id'],$d['observacoes']??null]);$id=(int)$pdo->lastInsertId();audit((int)$user['id'],'planejou','producao',$id,$d);json_response(['id'=>$id],201); }
    if ($action === 'production_confirm' && $method==='POST') { $d=input();$id=(int)($d['id']??0);$actual=(float)($d['quantidade_produzida']??0);if($actual<=0)json_response(['error'=>'Informe quantidade produzida positiva.'],422);$pdo->beginTransaction();$s=$pdo->prepare("SELECT * FROM producoes WHERE id=? AND status='planejada' FOR UPDATE");$s->execute([$id]);$production=$s->fetch();if(!$production)json_response(['error'=>'Produção não encontrada ou já confirmada.'],409);$pdo->prepare("UPDATE producoes SET status='produzida',quantidade_produzida=? WHERE id=?")->execute([$actual,$id]);$pdo->commit();audit((int)$user['id'],'confirmou','producao',$id,['quantidade_produzida'=>$actual,'baixa_automatica'=>false]);json_response(['ok'=>true,'baixa_estoque'=>false,'message'=>'Produção confirmada. O consumo do estoque permanece manual até validar as fichas e a regra operacional.']); }
    if ($action === 'buffet') {
        if($method==='GET')json_response(['items'=>$pdo->query('SELECT b.*,p.nome produto,f.nome ficha,u.nome usuario FROM buffet_registros b LEFT JOIN produtos p ON p.id=b.produto_id LEFT JOIN fichas_tecnicas f ON f.id=b.ficha_id JOIN usuarios u ON u.id=b.usuario_id ORDER BY b.data_operacao DESC LIMIT 200')->fetchAll()]);
        $d=input();$stmt=$pdo->prepare('INSERT INTO buffet_registros(data_operacao,turno,setor,ficha_id,produto_id,quantidade_preparada,quantidade_servida,sobra_reaproveitavel,descarte,unidade,motivo,custo_estimado,usuario_id,observacoes) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)');$stmt->execute([$d['data_operacao']??date('Y-m-d H:i:s'),$d['turno'],$d['setor'],$d['ficha_id']?:null,$d['produto_id']?:null,(float)($d['quantidade_preparada']??0),(float)($d['quantidade_servida']??0),(float)($d['sobra_reaproveitavel']??0),(float)($d['descarte']??0),$d['unidade'],$d['motivo']?:null,(float)($d['custo_estimado']??0),(int)$user['id'],$d['observacoes']?:null]);$id=(int)$pdo->lastInsertId();audit((int)$user['id'],'criou','buffet',$id,$d);json_response(['id'=>$id],201);
    }
    if ($action === 'breakages') {
        if($method==='GET')json_response(['items'=>$pdo->query('SELECT b.*,b.local_descricao local,u.nome usuario FROM quebras b JOIN usuarios u ON u.id=b.usuario_id ORDER BY b.data_registro DESC LIMIT 200')->fetchAll()]);
        $d=input();$stmt=$pdo->prepare('INSERT INTO quebras(item,categoria,quantidade,unidade,local_descricao,motivo,valor_estimado,usuario_id,reposicao_necessaria,observacoes) VALUES(?,?,?,?,?,?,?,?,?,?)');$stmt->execute([$d['item'],$d['categoria'],(float)$d['quantidade'],$d['unidade']??'un',$d['local']?:null,$d['motivo'],(float)($d['valor_estimado']??0),(int)$user['id'],!empty($d['reposicao_necessaria'])?1:0,$d['observacoes']?:null]);$id=(int)$pdo->lastInsertId();audit((int)$user['id'],'criou','quebra',$id,$d);json_response(['id'=>$id],201);
    }
    if ($action === 'lookups') {
        json_response(['categories'=>$pdo->query('SELECT id,nome FROM categorias_produto WHERE ativo=1 ORDER BY nome')->fetchAll(), 'units'=>$pdo->query('SELECT codigo,nome FROM unidades_medida ORDER BY ordem,nome')->fetchAll(), 'suppliers'=>$pdo->query('SELECT id,nome FROM fornecedores WHERE ativo=1 ORDER BY nome')->fetchAll(), 'products'=>$pdo->query('SELECT id,nome,unidade_compra,unidade_consumo,fator_conversao,preco_atual FROM produtos WHERE ativo=1 ORDER BY nome')->fetchAll(), 'recipes'=>$pdo->query("SELECT id,nome,tipo,rendimento_total,unidade_rendimento FROM fichas_tecnicas WHERE status<>'arquivada' ORDER BY nome")->fetchAll()]);
    }
    if ($action === 'recipe_versions' && $method==='GET') { $stmt=$pdo->prepare('SELECT v.*,u.nome usuario FROM fichas_tecnicas_versoes v JOIN usuarios u ON u.id=v.usuario_id WHERE v.ficha_id=? ORDER BY v.versao DESC');$stmt->execute([(int)($_GET['id']??0)]);$items=$stmt->fetchAll();foreach($items as &$item)$item['snapshot']=json_decode($item['snapshot'],true);json_response(['items'=>$items]); }
    if ($action === 'recipe_approve' && $method==='POST') { if(!in_array($user['perfil'],['admin','gestor'],true))json_response(['error'=>'Somente gestor ou administrador pode aprovar fichas.'],403);$d=input();$id=(int)($d['id']??0);$check=$pdo->prepare('SELECT COUNT(*) FROM ficha_tecnica_itens WHERE ficha_id=?');$check->execute([$id]);if((int)$check->fetchColumn()<1)json_response(['error'=>'Inclua pelo menos um ingrediente antes de aprovar.'],422);$pdo->prepare("UPDATE fichas_tecnicas SET status='aprovada',aprovada_por=?,aprovada_em=NOW() WHERE id=? AND status<>'arquivada'")->execute([(int)$user['id'],$id]);audit((int)$user['id'],'aprovou','ficha_tecnica',$id);json_response(['ok'=>true]); }
    if ($action === 'recipe_update' && $method==='POST') {
        $d=input();$id=(int)($d['id']??0);$pdo->beginTransaction();$lock=$pdo->prepare("SELECT * FROM fichas_tecnicas WHERE id=? AND status<>'arquivada' FOR UPDATE");$lock->execute([$id]);$old=$lock->fetch();if(!$old)json_response(['error'=>'Ficha não encontrada ou arquivada.'],404);
        $items=$d['itens']??[];if(!count($items))json_response(['error'=>'A ficha precisa ter ao menos um ingrediente.'],422);
        foreach($items as $item){$product=(int)($item['produto_id']??0);$component=(int)($item['ficha_componente_id']??0);if(($product>0)==($component>0))json_response(['error'=>'Cada ingrediente deve ser um produto ou uma sub-receita.'],422);if((float)($item['quantidade']??0)<=0)json_response(['error'=>'As quantidades precisam ser positivas.'],422);if($component&&recipe_would_cycle($pdo,$id,$component))json_response(['error'=>'Essa sub-receita criaria uma dependência circular.'],422);}
        $snapshot=recipe_snapshot($pdo,$id);$next=(int)$old['versao']+1;$history=$pdo->prepare('INSERT INTO fichas_tecnicas_versoes(ficha_id,versao,snapshot,usuario_id) VALUES(?,?,?,?)');$history->execute([$id,$old['versao'],json_encode($snapshot,JSON_UNESCAPED_UNICODE),(int)$user['id']]);
        $update=$pdo->prepare("UPDATE fichas_tecnicas SET nome=?,codigo=?,categoria_id=?,tipo=?,rendimento_total=?,unidade_rendimento=?,porcoes=?,tamanho_porcao=?,modo_preparo=?,equipamentos=?,tempo_preparo_minutos=?,validade_horas=?,armazenamento=?,observacoes=?,preco_venda=?,versao=?,status='rascunho',aprovada_por=NULL,aprovada_em=NULL WHERE id=?");$update->execute([$d['nome'],$d['codigo']?:null,$d['categoria_id']?:null,$d['tipo'],(float)$d['rendimento_total'],$d['unidade_rendimento'],(float)$d['porcoes'],(float)($d['tamanho_porcao']??0),$d['modo_preparo']?:null,$d['equipamentos']?:null,(int)($d['tempo_preparo_minutos']?:0)?:null,(int)($d['validade_horas']?:0)?:null,$d['armazenamento']?:null,$d['observacoes']?:null,(float)($d['preco_venda']??0),$next,$id]);
        $pdo->prepare('DELETE FROM ficha_tecnica_itens WHERE ficha_id=?')->execute([$id]);$insert=$pdo->prepare('INSERT INTO ficha_tecnica_itens(ficha_id,produto_id,ficha_componente_id,quantidade_bruta,quantidade_liquida,fator_correcao) VALUES(?,?,?,?,?,?)');foreach($items as $item){$qty=(float)$item['quantidade'];$correction=max((float)($item['fator_correcao']??1),0.000001);$insert->execute([$id,!empty($item['produto_id'])?(int)$item['produto_id']:null,!empty($item['ficha_componente_id'])?(int)$item['ficha_componente_id']:null,$qty,$qty/$correction,$correction]);}
        $pdo->commit();audit((int)$user['id'],'versionou','ficha_tecnica',$id,['versao'=>$next]);json_response(['id'=>$id,'versao'=>$next]);
    }
    if ($action === 'recipes') {
        if ($method === 'GET') {
            $recipes=$pdo->query("SELECT f.*, c.nome categoria FROM fichas_tecnicas f LEFT JOIN categorias_produto c ON c.id=f.categoria_id WHERE f.status <> 'arquivada' ORDER BY f.nome")->fetchAll();
            foreach($recipes as &$r){$s=$pdo->prepare('SELECT fi.*,p.nome produto,p.preco_atual,p.unidade_compra,p.unidade_consumo,p.fator_conversao,fc.nome ficha_componente FROM ficha_tecnica_itens fi LEFT JOIN produtos p ON p.id=fi.produto_id LEFT JOIN fichas_tecnicas fc ON fc.id=fi.ficha_componente_id WHERE fi.ficha_id=? ORDER BY fi.id');$s->execute([$r['id']]);$r['itens']=$s->fetchAll();$r['custo_total']=recipe_total_cost($pdo,(int)$r['id']);$r['custo_porcao']=$r['porcoes']?(float)$r['custo_total']/(float)$r['porcoes']:0;}
            json_response(['items'=>$recipes]);
        }
        $d=input(); $pdo->beginTransaction();
        $s=$pdo->prepare("INSERT INTO fichas_tecnicas (nome,codigo,categoria_id,tipo,rendimento_total,unidade_rendimento,porcoes,tamanho_porcao,modo_preparo,status,preco_venda,equipamentos,tempo_preparo_minutos,validade_horas,armazenamento,observacoes,autor_id) VALUES (?,?,?,?,?,?,?,?,?,'rascunho',?,?,?,?,?,?,?)");
        $s->execute([$d['nome'],$d['codigo']?:null,$d['categoria_id']?:null,$d['tipo']?:'prato',(float)$d['rendimento_total'],$d['unidade_rendimento'],(float)$d['porcoes'],(float)($d['tamanho_porcao']?:0),$d['modo_preparo']?:null,(float)($d['preco_venda']?:0),$d['equipamentos']?:null,(int)($d['tempo_preparo_minutos']?:0)?:null,(int)($d['validade_horas']?:0)?:null,$d['armazenamento']?:null,$d['observacoes']?:null,(int)$user['id']]); $id=(int)$pdo->lastInsertId();
        $s=$pdo->prepare('INSERT INTO ficha_tecnica_itens (ficha_id,produto_id,ficha_componente_id,quantidade_bruta,quantidade_liquida,fator_correcao) VALUES (?,?,?,?,?,?)');
        foreach(($d['itens']??[]) as $item){$product=(int)($item['produto_id']??0);$component=(int)($item['ficha_componente_id']??0);$qty=(float)($item['quantidade']??0);$correction=(float)($item['fator_correcao']??1);if(($product>0)==($component>0)||$qty<=0||$correction<=0)throw new InvalidArgumentException('Cada ingrediente deve ser válido, com quantidade e fator de correção positivos.');$s->execute([$id,$product?:null,$component?:null,$qty,$qty/$correction,$correction]);}
        $pdo->commit(); audit((int)$user['id'],'criou','ficha_tecnica',$id,$d); json_response(['id'=>$id],201);
    }
    if ($action === 'waste' && $method === 'GET') {
        $items = $pdo->query('SELECT d.*, p.nome produto, u.nome usuario FROM desperdicios d JOIN produtos p ON p.id=d.produto_id JOIN usuarios u ON u.id=d.usuario_id ORDER BY d.data_registro DESC, d.id DESC')->fetchAll();
        json_response(['items' => $items]);
    }
    if ($action === 'waste' && $method === 'POST') { $d=input();$clientId=trim((string)($d['client_id']??''));if($clientId!==''){$existing=$pdo->prepare('SELECT id FROM desperdicios WHERE client_id=?');$existing->execute([$clientId]);if($row=$existing->fetch())json_response(['ok'=>true,'id'=>(int)$row['id'],'duplicate'=>true]);}$productId=(int)$d['produto_id'];$quantity=(float)$d['quantidade'];$value=isset($d['valor_estimado'])&&$d['valor_estimado']!==''?(float)$d['valor_estimado']:null;if($value===null){$p=$pdo->prepare('SELECT preco_atual,unidade_compra,unidade_consumo,fator_conversao FROM produtos WHERE id=?');$p->execute([$productId]);$product=$p->fetch();if(!$product)json_response(['error'=>'Produto não encontrado.'],404);$factor=product_line_conversion((string)$d['unidade'],(string)$product['unidade_compra'],(string)$product['unidade_consumo'],(float)$product['fator_conversao']);$purchaseFactor=product_conversion((string)$product['unidade_compra'],(string)$product['unidade_consumo'],(float)$product['fator_conversao']);$value=$quantity*$factor*((float)$product['preco_atual']/$purchaseFactor);}$s=$pdo->prepare('INSERT INTO desperdicios (produto_id,quantidade,unidade,etapa,motivo,valor_estimado,data_registro,usuario_id,observacoes,client_id) VALUES (?,?,?,?,?,?,NOW(),?,?,?)');$s->execute([$productId,$quantity,$d['unidade'],$d['etapa'],$d['motivo'],$value,(int)$user['id'],$d['observacoes']?:null,$clientId?:null]);$id=(int)$pdo->lastInsertId();audit((int)$user['id'],'criou','desperdicio',$id,$d);json_response(['ok'=>true,'id'=>$id],201); }
    if ($action === 'waste_report' && $method === 'GET') {
        $from = valid_report_date($_GET['from'] ?? '') ? $_GET['from'] : date('Y-m-d', strtotime('-29 days'));
        $to = valid_report_date($_GET['to'] ?? '') ? $_GET['to'] : date('Y-m-d');
        if ($from > $to) { $swap = $from; $from = $to; $to = $swap; }
        $range = [$from . ' 00:00:00', $to . ' 23:59:59'];
        $s=$pdo->prepare('SELECT COUNT(*) quantidade_registros, COALESCE(SUM(valor_estimado),0) total_valor FROM desperdicios WHERE data_registro BETWEEN ? AND ?'); $s->execute($range); $summary=$s->fetch();
        $s=$pdo->prepare('SELECT p.id produto_id,p.nome produto,COUNT(*) ocorrencias,COALESCE(SUM(d.valor_estimado),0) valor FROM desperdicios d JOIN produtos p ON p.id=d.produto_id WHERE d.data_registro BETWEEN ? AND ? GROUP BY p.id,p.nome ORDER BY valor DESC,ocorrencias DESC LIMIT 10'); $s->execute($range); $byProduct=$s->fetchAll();
        $s=$pdo->prepare('SELECT motivo,COUNT(*) ocorrencias,COALESCE(SUM(valor_estimado),0) valor FROM desperdicios WHERE data_registro BETWEEN ? AND ? GROUP BY motivo ORDER BY valor DESC LIMIT 10'); $s->execute($range); $byReason=$s->fetchAll();
        $s=$pdo->prepare('SELECT DATE(data_registro) dia,COALESCE(SUM(valor_estimado),0) valor FROM desperdicios WHERE data_registro BETWEEN ? AND ? GROUP BY DATE(data_registro) ORDER BY dia'); $s->execute($range); $byDay=$s->fetchAll();
        $counts=['produtos'=>(int)$pdo->query('SELECT COUNT(*) FROM produtos WHERE ativo=1')->fetchColumn(),'fornecedores'=>(int)$pdo->query('SELECT COUNT(*) FROM fornecedores WHERE ativo=1')->fetchColumn(),'fichas'=>(int)$pdo->query("SELECT COUNT(*) FROM fichas_tecnicas WHERE status<>'arquivada'")->fetchColumn()];
        $productsByCategory=$pdo->query("SELECT COALESCE(c.nome,'Sem categoria') categoria,COUNT(p.id) quantidade FROM produtos p LEFT JOIN categorias_produto c ON c.id=p.categoria_id WHERE p.ativo=1 GROUP BY c.id,c.nome ORDER BY quantidade DESC LIMIT 10")->fetchAll();
        $suppliersByProducts=$pdo->query('SELECT f.nome fornecedor,COUNT(p.id) produtos_vinculados FROM fornecedores f LEFT JOIN produtos p ON p.fornecedor_principal_id=f.id AND p.ativo=1 WHERE f.ativo=1 GROUP BY f.id ORDER BY produtos_vinculados DESC,f.nome LIMIT 10')->fetchAll();
        $s=$pdo->query("SELECT f.*, c.nome categoria FROM fichas_tecnicas f LEFT JOIN categorias_produto c ON c.id=f.categoria_id WHERE f.status<>'arquivada' ORDER BY f.nome LIMIT 100"); $recipes=$s->fetchAll();
        foreach($recipes as &$recipe){$recipe['custo_total']=recipe_total_cost($pdo,(int)$recipe['id']);$recipe['custo_porcao']=$recipe['porcoes']?(float)$recipe['custo_total']/(float)$recipe['porcoes']:0;}
        $avgRecipeCost=count($recipes)?array_sum(array_column($recipes,'custo_total'))/count($recipes):0;
        usort($recipes,static fn($a,$b)=>(float)$b['custo_total']<=>(float)$a['custo_total']);
        $operations=[];
        $q=$pdo->prepare("SELECT COUNT(*) quantidade,COALESCE(SUM(descarte),0) descarte,COALESCE(SUM(custo_estimado),0) custo FROM buffet_registros WHERE data_operacao BETWEEN ? AND ?");$q->execute($range);$operations['buffet']=$q->fetch();
        $q=$pdo->prepare("SELECT COUNT(*) quantidade,COALESCE(SUM(valor_estimado),0) valor FROM quebras WHERE data_registro BETWEEN ? AND ?");$q->execute($range);$operations['quebras']=$q->fetch();
        $q=$pdo->prepare("SELECT COUNT(*) quantidade,COALESCE(SUM(i.quantidade*i.preco_unitario),0) valor_bruto FROM compras c JOIN compra_itens i ON i.compra_id=c.id WHERE c.status='recebida' AND c.data_compra BETWEEN ? AND ?");$q->execute($range);$operations['compras']=$q->fetch();
        $q=$pdo->prepare("SELECT COUNT(*) quantidade,COALESCE(SUM(quantidade_planejada),0) planejada,COALESCE(SUM(COALESCE(quantidade_produzida,0)),0) produzida FROM producoes WHERE registrada_em BETWEEN ? AND ?");$q->execute($range);$operations['producao']=$q->fetch();
        $operations['estoque']=['itens_abaixo_minimo'=>(int)$pdo->query("SELECT COUNT(*) FROM (SELECT p.id,p.estoque_minimo,COALESCE(SUM(CASE WHEN m.tipo IN ('entrada','devolucao','transferencia_entrada') THEN m.quantidade_base WHEN m.tipo IN ('consumo','perda','transferencia_saida') THEN -m.quantidade_base ELSE m.quantidade_base END),0) saldo FROM produtos p LEFT JOIN movimentacoes_estoque m ON m.produto_id=p.id AND m.local_id=1 WHERE p.ativo=1 GROUP BY p.id,p.estoque_minimo) saldos WHERE saldo<estoque_minimo")->fetchColumn()];
        json_response(['from'=>$from,'to'=>$to,'summary'=>$summary,'byProduct'=>$byProduct,'byReason'=>$byReason,'byDay'=>$byDay,'productsByCategory'=>$productsByCategory,'suppliersByProducts'=>$suppliersByProducts,'counts'=>$counts,'recipes'=>['quantidade'=>count($recipes),'custo_medio'=>$avgRecipeCost,'mais_custosas'=>array_slice($recipes,0,10)],'operations'=>$operations]);
    }
    if ($action === 'report_history' && $method === 'POST') {
        $d=input(); $report=$d['report']??null;
        if (!is_array($report) || !valid_report_date((string)($report['from']??'')) || !valid_report_date((string)($report['to']??''))) json_response(['error'=>'Gere um relatório válido antes de salvá-lo.'],422);
        $title=trim((string)($d['titulo']??'')) ?: 'Relatório de gestão';
        $encoded=json_encode($report,JSON_UNESCAPED_UNICODE|JSON_THROW_ON_ERROR);
        if (strlen($encoded)>5000000) json_response(['error'=>'O relatório excede o tamanho permitido para armazenamento.'],413);
        $stmt=$pdo->prepare('INSERT INTO relatorios_salvos (titulo,data_inicio,data_fim,dados,usuario_id) VALUES (?,?,?,?,?)');
        $stmt->execute([substr($title,0,180),$report['from'],$report['to'],$encoded,(int)$user['id']]);
        $id=(int)$pdo->lastInsertId(); audit((int)$user['id'],'salvou','relatorio',$id,['titulo'=>$title]); json_response(['id'=>$id],201);
    }
    if ($action === 'report_history' && $method === 'GET') {
        $page=max(1,(int)($_GET['page']??1)); $perPage=50; $total=(int)$pdo->query('SELECT COUNT(*) FROM relatorios_salvos')->fetchColumn();
        $stmt=$pdo->prepare('SELECT r.id,r.titulo,r.data_inicio,r.data_fim,r.criado_em,u.nome usuario FROM relatorios_salvos r JOIN usuarios u ON u.id=r.usuario_id ORDER BY r.criado_em DESC,r.id DESC LIMIT ? OFFSET ?');
        $stmt->bindValue(1,$perPage,PDO::PARAM_INT); $stmt->bindValue(2,($page-1)*$perPage,PDO::PARAM_INT); $stmt->execute();
        json_response(['items'=>$stmt->fetchAll(),'total'=>$total,'page'=>$page,'perPage'=>$perPage]);
    }
    if ($action === 'report_history_item' && $method === 'GET') {
        $stmt=$pdo->prepare('SELECT r.id,r.titulo,r.data_inicio,r.data_fim,r.dados,r.criado_em,u.nome usuario FROM relatorios_salvos r JOIN usuarios u ON u.id=r.usuario_id WHERE r.id=?');
        $stmt->execute([(int)($_GET['id']??0)]); $item=$stmt->fetch();
        if (!$item) json_response(['error'=>'Relatório não encontrado.'],404);
        $item['report']=json_decode($item['dados'],true); unset($item['dados']); json_response($item);
    }
    if ($action === 'search' && $method === 'GET') {
        $type=(string)($_GET['type']??''); $q=trim((string)($_GET['q']??'')); $like='%'.$q.'%'; $limit=100;
        if ($type==='products') {
            $stmt=$pdo->prepare('SELECT p.*,c.nome categoria,f.nome fornecedor FROM produtos p LEFT JOIN categorias_produto c ON c.id=p.categoria_id LEFT JOIN fornecedores f ON f.id=p.fornecedor_principal_id WHERE p.ativo=1 AND (?=1 OR p.nome LIKE ? OR p.codigo LIKE ? OR p.marca LIKE ? OR c.nome LIKE ? OR f.nome LIKE ?) ORDER BY p.nome LIMIT '.$limit);
            $stmt->execute([$q===''?1:0,$like,$like,$like,$like,$like]);
        } elseif ($type==='suppliers') {
            $stmt=$pdo->prepare('SELECT f.*,COUNT(p.id) produtos_vinculados FROM fornecedores f LEFT JOIN produtos p ON p.fornecedor_principal_id=f.id AND p.ativo=1 WHERE f.ativo=1 AND (?=1 OR f.nome LIKE ? OR f.documento LIKE ? OR f.telefone LIKE ? OR f.contato LIKE ?) GROUP BY f.id ORDER BY f.nome LIMIT '.$limit);
            $stmt->execute([$q===''?1:0,$like,$like,$like,$like]);
        } elseif ($type==='recipes') {
            $stmt=$pdo->prepare("SELECT f.*,c.nome categoria FROM fichas_tecnicas f LEFT JOIN categorias_produto c ON c.id=f.categoria_id WHERE f.status<>'arquivada' AND (?=1 OR f.nome LIKE ? OR f.codigo LIKE ? OR f.tipo LIKE ? OR c.nome LIKE ?) ORDER BY f.nome LIMIT ".$limit);
            $stmt->execute([$q===''?1:0,$like,$like,$like,$like]);
            $items=$stmt->fetchAll(); foreach($items as &$recipe){$x=$pdo->prepare('SELECT fi.*,p.nome produto,p.preco_atual,p.unidade_compra,p.unidade_consumo,p.fator_conversao,fc.nome ficha_componente FROM ficha_tecnica_itens fi LEFT JOIN produtos p ON p.id=fi.produto_id LEFT JOIN fichas_tecnicas fc ON fc.id=fi.ficha_componente_id WHERE fi.ficha_id=? ORDER BY fi.id');$x->execute([$recipe['id']]);$recipe['itens']=$x->fetchAll();$recipe['custo_total']=recipe_total_cost($pdo,(int)$recipe['id']);$recipe['custo_porcao']=$recipe['porcoes']?(float)$recipe['custo_total']/(float)$recipe['porcoes']:0;} json_response(['items'=>$items,'limit'=>$limit]);
        } elseif ($type==='waste') {
            $from=valid_report_date($_GET['from']??'')?$_GET['from']:'1000-01-01';$to=valid_report_date($_GET['to']??'')?$_GET['to']:date('Y-m-d');
            if ($from>$to) { $swap=$from; $from=$to; $to=$swap; }
            $stmt=$pdo->prepare('SELECT d.*,p.nome produto,u.nome usuario FROM desperdicios d JOIN produtos p ON p.id=d.produto_id JOIN usuarios u ON u.id=d.usuario_id WHERE d.data_registro BETWEEN ? AND ? AND (?=1 OR p.nome LIKE ? OR d.motivo LIKE ? OR d.etapa LIKE ? OR d.observacoes LIKE ?) ORDER BY d.data_registro DESC,d.id DESC LIMIT '.$limit);
            $stmt->execute([$from.' 00:00:00',$to.' 23:59:59',$q===''?1:0,$like,$like,$like,$like]);
        } else { json_response(['error'=>'Escolha uma seção válida para pesquisar.'],422); }
        json_response(['items'=>$stmt->fetchAll(),'limit'=>$limit]);
    }
    json_response(['error'=>'Ação não encontrada.'],404);
} catch (Throwable $e) { if(isset($pdo)&&$pdo->inTransaction())$pdo->rollBack(); $reference=bin2hex(random_bytes(4)); error_log('[restaurante-api]['.$reference.'] '.$e->getMessage()); json_response(['error'=>'Erro interno. Informe a referência ao suporte: '.$reference],500); }

function unit_scale(string $unit): ?array { return ['kg'=>['massa',1000],'g'=>['massa',1],'l'=>['volume',1000],'ml'=>['volume',1]][strtolower($unit)]??null; }
function product_conversion(string $purchaseUnit,string $consumptionUnit,float $configured): float { $purchaseScale=unit_scale($purchaseUnit);$consumptionScale=unit_scale($consumptionUnit);if($purchaseScale!==null&&$consumptionScale!==null&&$purchaseScale[0]===$consumptionScale[0])return $purchaseScale[1]/$consumptionScale[1];return max($configured,0.000001); }
function product_line_conversion(string $lineUnit,string $purchaseUnit,string $consumptionUnit,float $configured): float { if($lineUnit===$purchaseUnit)return product_conversion($purchaseUnit,$consumptionUnit,$configured);$line=unit_scale($lineUnit);$consumption=unit_scale($consumptionUnit);if($line!==null&&$consumption!==null&&$line[0]===$consumption[0])return $line[1]/$consumption[1];throw new InvalidArgumentException('Unidade da compra incompatível com a unidade cadastrada para este produto.'); }
function stock_balance(PDO $pdo,int $productId,int $locationId=1): float { $stmt=$pdo->prepare("SELECT COALESCE(SUM(CASE WHEN tipo IN ('entrada','devolucao','transferencia_entrada') THEN quantidade_base WHEN tipo IN ('consumo','perda','transferencia_saida') THEN -quantidade_base ELSE quantidade_base END),0) FROM movimentacoes_estoque WHERE produto_id=? AND local_id=?");$stmt->execute([$productId,$locationId]);return (float)$stmt->fetchColumn(); }
function recipe_total_cost(PDO $pdo,int $recipeId,array $stack=[]): float { static $memo=[];if(isset($memo[$recipeId]))return $memo[$recipeId];if(in_array($recipeId,$stack,true))throw new RuntimeException('Foi encontrada uma dependência circular entre fichas.');$stack[]=$recipeId;$stmt=$pdo->prepare('SELECT fi.quantidade_liquida,fi.produto_id,fi.ficha_componente_id,p.preco_atual,p.unidade_compra,p.unidade_consumo,p.fator_conversao,fc.rendimento_total FROM ficha_tecnica_itens fi LEFT JOIN produtos p ON p.id=fi.produto_id LEFT JOIN fichas_tecnicas fc ON fc.id=fi.ficha_componente_id WHERE fi.ficha_id=?');$stmt->execute([$recipeId]);$total=0;foreach($stmt->fetchAll() as $item){if($item['produto_id']!==null){$factor=product_conversion((string)$item['unidade_compra'],(string)$item['unidade_consumo'],(float)$item['fator_conversao']);$unitCost=(float)$item['preco_atual']/$factor;}else{$yield=max((float)$item['rendimento_total'],0.000001);$unitCost=recipe_total_cost($pdo,(int)$item['ficha_componente_id'],$stack)/$yield;}$total+=(float)$item['quantidade_liquida']*$unitCost;}return $memo[$recipeId]=round($total,2); }
function recipe_would_cycle(PDO $pdo,int $targetId,int $componentId,array $seen=[]): bool { if($componentId===$targetId)return true;if(isset($seen[$componentId]))return false;$seen[$componentId]=true;$stmt=$pdo->prepare('SELECT ficha_componente_id FROM ficha_tecnica_itens WHERE ficha_id=? AND ficha_componente_id IS NOT NULL');$stmt->execute([$componentId]);foreach($stmt->fetchAll(PDO::FETCH_COLUMN) as $child)if(recipe_would_cycle($pdo,$targetId,(int)$child,$seen))return true;return false; }
function recipe_snapshot(PDO $pdo,int $id): array { $stmt=$pdo->prepare('SELECT * FROM fichas_tecnicas WHERE id=?');$stmt->execute([$id]);$recipe=$stmt->fetch()?:[];$items=$pdo->prepare('SELECT * FROM ficha_tecnica_itens WHERE ficha_id=? ORDER BY id');$items->execute([$id]);$recipe['itens']=$items->fetchAll();return $recipe; }
function valid_report_date(string $value): bool { if (!preg_match('/^(\d{4})-(\d{2})-(\d{2})$/', $value, $m)) return false; return checkdate((int)$m[2], (int)$m[3], (int)$m[1]); }
