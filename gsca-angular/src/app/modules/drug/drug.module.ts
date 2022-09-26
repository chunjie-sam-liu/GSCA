import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { DrugRoutingModule } from './drug-routing.module';
import { DrugComponent } from './drug.component';
import { SharedModule } from 'src/app/shared/shared.module';
import { GdscComponent } from './gdsc/gdsc.component';
import { SearchBoxComponent } from './search-box/search-box.component';
import { CtrpComponent } from './ctrp/ctrp.component';
import { DocCtrpComponent } from './ctrp/doc-ctrp/doc-ctrp.component';
import { DocGdscComponent } from './gdsc/doc-gdsc/doc-gdsc.component';
import { GsdbComponent } from './search-box/gsdb/gsdb.component';

@NgModule({
  declarations: [DrugComponent, GdscComponent, SearchBoxComponent, CtrpComponent, DocCtrpComponent, DocGdscComponent, GsdbComponent],
  imports: [CommonModule, DrugRoutingModule, SharedModule],
})
export class DrugModule {}
