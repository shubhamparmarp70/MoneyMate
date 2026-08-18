package com.example.moneymanager.repository;

import com.example.moneymanager.entity.ProfileEntity;
import org.springframework.context.annotation.Profile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ProfileRepository extends JpaRepository <ProfileEntity, Long>{

    //select * from ProfileRepository where email = ?
   Optional<ProfileEntity> findByEmail(String email);


   // select * from tbl_profiles where activation_token = ?
  Optional<ProfileEntity> findByActivationToken(String activationToken);

}
