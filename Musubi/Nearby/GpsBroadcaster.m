/*
 * Copyright 2012 The Stanford MobiSocial Laboratory
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


//
//  GpsBroadcaster.h
//  musubi
//
//  Created by T.J. Purtell on 6/17/12.
//  Copyright (c) 2012 Stanford MobiSocial Labratory. All rights reserved.
//


#import "GpsBroadcaster.h"
#import "NearbyFeed.h"


@implementation GpsBroadcaster
@synthesize feed;
- (void)broadcastNearby:(NearbyFeed*)feedData withPassword:(NSString*)password onSuccess:(void(^)())success onFail:(void(^)(NSError*))fail {
    feed = feedData;
    [self lookupAndCall:^(CLLocation *location) {

        
/*
 SQLiteOpenHelper db = App.getDatabaseSource(mContext);
 FeedManager fm = new FeedManager(db);
 IdentitiesManager im = new IdentitiesManager(db);
 String group_name = UiUtil.getFeedNameFromMembersList(fm, mFeed);
 byte[] group_capability = mFeed.capability_;
 List<MIdentity> owned = im.getOwnedIdentities();
 MIdentity sharer = null;
 for(MIdentity i : owned) {
 if(i.type_ != Authority.Local) {
 sharer = i;
 break;
 }
 }
 String sharer_name = UiUtil.safeNameForIdentity(sharer);
 byte[] sharer_hash = sharer.principalHash_;
 
 byte[] thumbnail = im.getMusubiThumbnail(sharer) != null ? sharer.musubiThumbnail_ : im.getThumbnail(sharer);
 int member_count = fm.getFeedMemberCount(mFeed.id_);
 
 JSONObject group = new JSONObject();
 group.put("group_name", group_name);
 group.put("group_capability", Base64.encodeToString(group_capability, Base64.DEFAULT));
 group.put("sharer_name", sharer_name);
 group.put("sharer_type", sharer.type_.ordinal());
 group.put("sharer_hash", Base64.encodeToString(sharer_hash, Base64.DEFAULT));
 if(thumbnail != null)
 group.put("thumbnail", Base64.encodeToString(thumbnail, Base64.DEFAULT));
 group.put("member_count", member_count);
 
 byte[] key = Util.sha256(("happysalt621" + mmPassword).getBytes());
 byte[] data = group.toString().getBytes();
 byte[] iv = new byte[16];
 new SecureRandom().nextBytes(iv);
 
 byte[] partial_enc_data; 
 Cipher cipher;
 AlgorithmParameterSpec iv_spec;
 SecretKeySpec sks;
 try {
 cipher = Cipher.getInstance("AES/CBC/PKCS7Padding");
 } catch (Exception e) {
 throw new RuntimeException("AES not supported on this platform", e);
 }
 try {
 iv_spec = new IvParameterSpec(iv);
 sks = new SecretKeySpec(key, "AES");
 cipher.init(Cipher.ENCRYPT_MODE, sks, iv_spec);
 } catch (Exception e) {
 throw new RuntimeException("bad iv or key", e);
 }
 try {
 partial_enc_data = cipher.doFinal(data);
 } catch (Exception e) {
 throw new RuntimeException("body encryption failed", e);
 }
 
 TByteArrayList bal = new TByteArrayList(iv.length + partial_enc_data.length);
 bal.add(iv);
 bal.add(partial_enc_data);
 byte[] enc_data = bal.toArray();
 
 
 if (DBG) Log.d(TAG, "Posting to gps server...");
 
 
 
 Uri uri = Uri.parse("http://bumblebee.musubi.us:6253/nearbyapi/0/sharegroup");
 
 StringBuffer sb = new StringBuffer();
 DefaultHttpClient client = new DefaultHttpClient();
 HttpPost httpPost = new HttpPost(uri.toString());
 httpPost.addHeader("Content-Type", "application/json");
 JSONArray buckets = new JSONArray();
 JSONObject descriptor = new JSONObject();
 
 double lat = mmLocation.getLatitude();
 double lng = mmLocation.getLongitude();
 long[] coords = GridHandler.getGridCoords(lat, lng, 5280 / 2);
 for(long c : coords) {
 MessageDigest md;
 try {
 byte[] obfuscate = ("sadsalt193s" + mmPassword).getBytes();
 md = MessageDigest.getInstance("SHA-256");
 ByteBuffer b = ByteBuffer.allocate(8 + obfuscate.length);
 b.putLong(c);
 b.put(obfuscate);
 String secret_bucket = Base64.encodeToString(md.digest(b.array()), Base64.DEFAULT);
 buckets.put(buckets.length(), secret_bucket);
 } catch (NoSuchAlgorithmException e) {
 throw new RuntimeException("your platform does not support sha256", e);
 }
 }
 descriptor.put("buckets", buckets);
 descriptor.put("data", Base64.encodeToString(enc_data, Base64.DEFAULT));
 descriptor.put("expiration", new Date().getTime() + 1000 * 60 * 60);
 
 httpPost.setEntity(new StringEntity(descriptor.toString()));
 try {
 HttpResponse execute = client.execute(httpPost);
 InputStream content = execute.getEntity().getContent();
 BufferedReader buffer = new BufferedReader(new InputStreamReader(content));
 String s = "";
 while ((s = buffer.readLine()) != null) {
 if (isCancelled()) {
 return null;
 }
 sb.append(s);
 }
 if(sb.toString().equals("ok"))
 mSucceeded = true;
 else {
 System.err.println(sb);
 }
 } catch (Exception e) {
 e.printStackTrace();
 }
 //TODO: report failures etc
 } catch (Exception e) {
 Log.e(TAG, "Failed to broadcast group", e);
 }
 return null;
 */
    
    
    } orFail:^(NSError *error) {
        fail(error);
    }];
}

@end
