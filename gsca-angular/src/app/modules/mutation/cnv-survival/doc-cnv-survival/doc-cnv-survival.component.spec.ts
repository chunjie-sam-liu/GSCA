import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocCnvSurvivalComponent } from './doc-cnv-survival.component';

describe('DocCnvSurvivalComponent', () => {
  let component: DocCnvSurvivalComponent;
  let fixture: ComponentFixture<DocCnvSurvivalComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocCnvSurvivalComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocCnvSurvivalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
