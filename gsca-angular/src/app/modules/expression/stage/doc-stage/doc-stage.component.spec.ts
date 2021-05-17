import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocStageComponent } from './doc-stage.component';

describe('DocStageComponent', () => {
  let component: DocStageComponent;
  let fixture: ComponentFixture<DocStageComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocStageComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocStageComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
